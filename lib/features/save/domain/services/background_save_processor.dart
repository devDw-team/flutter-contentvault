import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import 'content_metadata_extractor.dart';
import 'platform_parser_selector.dart';
import 'pending_saves_repository.dart';
import '../models/pending_save_model.dart';

class BackgroundSaveProcessor {
  final AppDatabase _database;
  final ContentMetadataExtractor _metadataExtractor;
  final PlatformParserSelector _platformSelector;
  final PendingSavesRepository _pendingSavesRepository;
  final _uuid = const Uuid();
  
  Timer? _processingTimer;
  bool _isProcessing = false;

  BackgroundSaveProcessor({
    required AppDatabase database,
    required ContentMetadataExtractor metadataExtractor,
    required PlatformParserSelector platformSelector,
    required PendingSavesRepository pendingSavesRepository,
  })  : _database = database,
        _metadataExtractor = metadataExtractor,
        _platformSelector = platformSelector,
        _pendingSavesRepository = pendingSavesRepository;

  void startProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => processQueue(),
    );
  }

  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    try {
      // Get pending saves
      final pendingSaves = await _pendingSavesRepository.getPendingSaves(limit: 5);

      for (final pendingSave in pendingSaves) {
        await _processSingleSave(pendingSave);
      }
    } catch (e) {
      debugPrint('Background processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processSingleSave(PendingSaveModel pendingSave) async {
    try {
      debugPrint('BackgroundSaveProcessor: Processing save for URL: ${pendingSave.url}');
      
      // Update status to processing
      await _pendingSavesRepository.update(
        pendingSave.id,
        pendingSave.copyWith(status: 'processing'),
      );

      // Ensure URL is properly formatted
      String processedUrl = pendingSave.url.trim();
      
      // Special handling for Threads URLs
      if (processedUrl.contains('threads.net') && !processedUrl.startsWith('http')) {
        processedUrl = 'https://$processedUrl';
        debugPrint('BackgroundSaveProcessor: Fixed Threads URL to: $processedUrl');
      }

      // Parse content using appropriate parser
      final content = await _platformSelector.parseContent(processedUrl);
      
      if (content == null) {
        // Fallback to metadata extractor if parser is not available
        final metadata = await _metadataExtractor.extractMetadata(
          url: processedUrl,
          platform: pendingSave.sourcePlatform,
        );

        // Create content entry from metadata
        final contentId = _uuid.v4();
        await _database.into(_database.contentsTable).insert(
          ContentsTableCompanion.insert(
            id: contentId,
            title: metadata.title ?? pendingSave.title ?? 'Untitled',
            url: processedUrl,
            description: Value(metadata.description),
            thumbnailUrl: Value(metadata.thumbnailUrl),
            contentType: _mapPlatformToContentType(pendingSave.sourcePlatform),
            sourcePlatform: pendingSave.sourcePlatform,
            author: Value(metadata.author),
            publishedAt: Value(metadata.publishedAt),
            contentText: Value(metadata.contentText ?? pendingSave.text),
            metadata: Value(metadata.toJson()),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Save parsed content directly
        await _database.into(_database.contentsTable).insert(
          ContentsTableCompanion.insert(
            id: content.id,
            title: content.title,
            url: content.url,
            description: Value(content.description),
            thumbnailUrl: Value(content.thumbnailUrl),
            contentType: content.contentType,
            sourcePlatform: content.sourcePlatform,
            author: Value(content.author),
            publishedAt: Value(content.publishedAt),
            contentText: Value(content.contentText),
            metadata: Value(content.metadata),
            createdAt: content.createdAt,
            updatedAt: content.updatedAt,
          ),
        );
        
        // If it's an article, save additional content
        if (content.contentType == 'article' && content.metadata != null) {
          await _saveArticleContent(content);
        }
      }

      // Update pending save as completed
      await _pendingSavesRepository.update(
        pendingSave.id,
        pendingSave.copyWith(
          status: 'completed',
          processedAt: DateTime.now(),
        ),
      );

      // Clean up old completed saves (older than 7 days)
      await _cleanupOldSaves();
      
    } catch (e) {
      debugPrint('BackgroundSaveProcessor: Error processing save: $e');
      debugPrint('BackgroundSaveProcessor: Stack trace: ${StackTrace.current}');
      
      // Update with error
      await _pendingSavesRepository.update(
        pendingSave.id,
        pendingSave.copyWith(
          status: 'failed',
          errorMessage: e.toString(),
          retryCount: pendingSave.retryCount + 1,
        ),
      );

      // Retry logic
      if (pendingSave.retryCount < 3) {
        await Future.delayed(Duration(minutes: pendingSave.retryCount + 1));
        await _pendingSavesRepository.update(
          pendingSave.id,
          pendingSave.copyWith(status: 'pending'),
        );
      }
    }
  }

  String _mapPlatformToContentType(String platform) {
    switch (platform) {
      case 'youtube':
        return 'youtube';
      case 'twitter':
        return 'twitter';
      case 'threads':
        return 'threads';
      case 'article':
        return 'article';
      default:
        return 'web';
    }
  }

  Future<void> _cleanupOldSaves() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    await _pendingSavesRepository.cleanupOldCompleted(cutoffDate);
  }

  Future<void> _saveArticleContent(Content content) async {
    try {
      final metadata = content.metadata;
      if (metadata == null) return;
      
      final metadataMap = jsonDecode(metadata) as Map<String, dynamic>;
      
      await _database.into(_database.articleContentTable).insert(
        ArticleContentTableCompanion.insert(
          id: metadataMap['articleId'] ?? content.id,
          contentId: content.id,
          contentHtml: metadataMap['contentHtml'] ?? '',
          contentText: content.contentText ?? '',
          images: jsonEncode(metadataMap['images'] ?? []),
          readingTimeMinutes: metadataMap['readingTimeMinutes'] ?? 0,
          metadata: Value(content.metadata),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('BackgroundSaveProcessor: Error saving article content: $e');
    }
  }

  Future<void> processImmediately(String pendingSaveId) async {
    final pendingSave = await _pendingSavesRepository.getById(pendingSaveId);
    
    if (pendingSave != null) {
      await _processSingleSave(pendingSave);
    }
  }
}