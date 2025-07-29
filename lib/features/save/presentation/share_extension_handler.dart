import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/app_database.dart';
import '../../save/domain/services/url_validator.dart';
import '../../save/domain/services/platform_parser_selector.dart';
import '../../save/domain/services/pending_saves_repository.dart';
import '../../save/domain/models/pending_save_model.dart';

class ShareExtensionHandler {
  final AppDatabase _database;
  final UrlValidator _urlValidator;
  final PlatformParserSelector _platformSelector;
  final PendingSavesRepository _pendingSavesRepository;
  final _uuid = const Uuid();
  
  StreamSubscription? _mediaStreamSubscription;

  ShareExtensionHandler({
    required AppDatabase database,
    required UrlValidator urlValidator,
    required PlatformParserSelector platformSelector,
    required PendingSavesRepository pendingSavesRepository,
  })  : _database = database,
        _urlValidator = urlValidator,
        _platformSelector = platformSelector,
        _pendingSavesRepository = pendingSavesRepository;

  void initialize() {
    // Handle media sharing (text and images)
    _mediaStreamSubscription = ReceiveSharingIntent.instance.getMediaStream()
        .listen(_handleSharedMedia, onError: (error) {
          debugPrint('ShareExtensionHandler stream error: $error');
        });
    
    // Handle initial shared data on app launch
    _handleInitialSharedData();
  }

  Future<void> _handleInitialSharedData() async {
    try {
      debugPrint('ShareExtensionHandler: Checking for initial shared data...');
      
      // First try native channel
      try {
        const platform = MethodChannel('contentvault/userdefaults');
        final List<dynamic> sharedData = await platform.invokeMethod('getSharedData');
        
        if (sharedData.isNotEmpty) {
          debugPrint('ShareExtensionHandler: Found ${sharedData.length} items from native channel');
          
          List<Map<String, dynamic>> successfullyProcessed = [];
          
          for (var item in sharedData) {
            if (item is Map) {
              final path = item['path'] as String?;
              if (path != null && path.isNotEmpty) {
                debugPrint('ShareExtensionHandler: Processing native item: $path');
                try {
                  await _processSave(url: path);
                  successfullyProcessed.add(Map<String, dynamic>.from(item));
                  debugPrint('ShareExtensionHandler: Successfully processed: $path');
                } catch (e) {
                  debugPrint('ShareExtensionHandler: Failed to process $path: $e');
                  // Continue processing other items
                }
              }
            }
          }
          
          // Remove only successfully processed items from UserDefaults
          if (successfullyProcessed.isNotEmpty) {
            debugPrint('ShareExtensionHandler: Processed ${successfullyProcessed.length} out of ${sharedData.length} items');
            
            // Get remaining items
            final remainingItems = sharedData.where((item) {
              if (item is Map) {
                final path = item['path'] as String?;
                return !successfullyProcessed.any((processed) => processed['path'] == path);
              }
              return true;
            }).toList();
            
            if (remainingItems.isEmpty) {
              // Clear all if all were processed
              await platform.invokeMethod('clearSharedData');
            } else {
              // Update with remaining items only
              // This would need a new method in native code to update the list
              debugPrint('ShareExtensionHandler: ${remainingItems.length} items remain unprocessed');
            }
          }
          return;
        }
      } catch (e) {
        debugPrint('ShareExtensionHandler: Native channel error: $e');
      }
      
      // Fallback to receive_sharing_intent
      final sharedMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      
      if (sharedMedia != null && sharedMedia.isNotEmpty) {
        debugPrint('ShareExtensionHandler: Found ${sharedMedia.length} initial shared items');
        await _handleSharedMedia(sharedMedia);
        // Reset the intent after processing
        ReceiveSharingIntent.instance.reset();
      } else {
        debugPrint('ShareExtensionHandler: No initial shared data found');
      }
    } catch (e) {
      debugPrint('ShareExtensionHandler: Error handling initial shared data: $e');
    }
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> sharedFiles) async {
    if (sharedFiles.isEmpty) return;
    
    debugPrint('ShareExtensionHandler: Received ${sharedFiles.length} shared items');
    
    for (final file in sharedFiles) {
      debugPrint('ShareExtensionHandler: Processing file - type: ${file.type}, path: ${file.path}');
      
      // For text/URL sharing, the path contains the shared text
      if (file.path != null) {
        final String path = file.path;
        final urls = _extractUrls(path);
        debugPrint('ShareExtensionHandler: Extracted URLs: $urls');
        
        if (urls.isNotEmpty) {
          await _processSave(url: urls.first, text: path);
        } else {
          debugPrint('ShareExtensionHandler: No valid URLs found in: $path');
        }
      }
    }
  }

  Future<void> _handleSharedText(String sharedText) async {
    final urls = _extractUrls(sharedText);
    if (urls.isNotEmpty) {
      await _processSave(url: urls.first, text: sharedText);
    }
  }

  List<String> _extractUrls(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    
    return urlPattern.allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  Future<void> _processSave({
    required String url,
    String? title,
    String? text,
    List<Uint8List>? images,
  }) async {
    try {
      debugPrint('ShareExtensionHandler: Processing save for URL: $url');
      
      // Validate URL
      if (!_urlValidator.isValid(url)) {
        debugPrint('ShareExtensionHandler: Invalid URL format: $url');
        throw Exception('Invalid URL format');
      }

      // Check for duplicate within 24 hours
      final isDuplicate = await _checkDuplicate(url);
      if (isDuplicate) {
        debugPrint('ShareExtensionHandler: Duplicate URL found: $url');
        throw Exception('This URL was already saved within the last 24 hours');
      }

      // Determine platform
      final platform = _platformSelector.selectPlatform(url);
      debugPrint('ShareExtensionHandler: Detected platform: $platform');

      // Create pending save entry
      final pendingSaveId = _uuid.v4();
      debugPrint('ShareExtensionHandler: Creating pending save with ID: $pendingSaveId');
      
      await _pendingSavesRepository.insert(
        PendingSaveModel(
          id: pendingSaveId,
          url: url,
          title: title,
          text: text,
          images: images != null ? _serializeImagesToJson(images) : null,
          sourcePlatform: platform,
          status: 'pending',
          errorMessage: null,
          retryCount: 0,
          createdAt: DateTime.now(),
          processedAt: null,
        ),
      );

      debugPrint('ShareExtensionHandler: Pending save created successfully');
      
      // Trigger background processing
      await _triggerBackgroundProcessing(pendingSaveId);
      
    } catch (e) {
      // Log error and show user feedback
      debugPrint('ShareExtensionHandler: Error processing save: $e');
      rethrow;
    }
  }

  Future<bool> _checkDuplicate(String url) async {
    final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
    final query = _database.select(_database.contentsTable)
      ..where((tbl) => tbl.url.equals(url));
    
    final allContents = await query.get();
    
    // Filter by date in Dart
    final recentContent = allContents.where((content) => 
      content.createdAt.isAfter(cutoffDate)
    ).toList();
    
    return recentContent.isNotEmpty;
  }

  String _serializeImagesToJson(List<Uint8List> images) {
    // Convert images to base64 encoded strings
    final base64Images = images.map((image) {
      return base64Encode(image);
    }).toList();
    
    return jsonEncode(base64Images);
  }

  Future<void> _triggerBackgroundProcessing(String pendingSaveId) async {
    // This will be handled by the background queue processor
    // For now, we'll just mark it as ready for processing
    debugPrint('Pending save created with ID: $pendingSaveId');
  }

  void dispose() {
    _mediaStreamSubscription?.cancel();
  }
}

// Provider for ShareExtensionHandler
final shareExtensionHandlerProvider = Provider<ShareExtensionHandler>((ref) {
  final database = GetIt.instance<AppDatabase>();
  final pendingSavesRepository = GetIt.instance<PendingSavesRepository>();
  
  return ShareExtensionHandler(
    database: database,
    urlValidator: UrlValidator(),
    platformSelector: PlatformParserSelector(),
    pendingSavesRepository: pendingSavesRepository,
  );
});