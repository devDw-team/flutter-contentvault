import 'dart:async';
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
      (_) => _processQueue(),
    );
  }

  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  Future<void> _processQueue() async {
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
      // Update status to processing
      await _pendingSavesRepository.update(
        pendingSave.id,
        pendingSave.copyWith(status: 'processing'),
      );

      // Extract metadata based on platform
      final metadata = await _metadataExtractor.extractMetadata(
        url: pendingSave.url,
        platform: pendingSave.sourcePlatform,
      );

      // Create content entry
      final contentId = _uuid.v4();
      await _database.into(_database.contentsTable).insert(
        ContentsTableCompanion.insert(
          id: contentId,
          title: metadata.title ?? pendingSave.title ?? 'Untitled',
          url: pendingSave.url,
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

  Future<void> processImmediately(String pendingSaveId) async {
    final pendingSave = await _pendingSavesRepository.getById(pendingSaveId);
    
    if (pendingSave != null) {
      await _processSingleSave(pendingSave);
    }
  }
}