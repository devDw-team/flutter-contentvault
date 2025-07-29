import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/services/content_metadata_extractor.dart';
import '../api_clients/youtube_api_client.dart';

class YouTubeParser {
  final YouTubeApiClient _apiClient;
  final ContentMetadataExtractor _metadataExtractor;
  final _uuid = const Uuid();

  YouTubeParser({
    required YouTubeApiClient apiClient,
    required ContentMetadataExtractor metadataExtractor,
  })  : _apiClient = apiClient,
        _metadataExtractor = metadataExtractor;

  static const _youtubeUrlPatterns = [
    r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})',
    r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]{11})',
    r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/v\/([a-zA-Z0-9_-]{11})',
    r'(?:https?:\/\/)?youtu\.be\/([a-zA-Z0-9_-]{11})',
    r'(?:https?:\/\/)?m\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})',
    r'(?:https?:\/\/)?www\.youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})',
  ];

  bool canParse(String url) {
    for (final pattern in _youtubeUrlPatterns) {
      if (RegExp(pattern).hasMatch(url)) {
        return true;
      }
    }
    return false;
  }

  String? extractVideoId(String url) {
    for (final pattern in _youtubeUrlPatterns) {
      final match = RegExp(pattern).firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    
    // Handle additional cases with query parameters
    final uri = Uri.tryParse(url);
    if (uri != null && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    
    return null;
  }

  Future<Content> parse(String url) async {
    final videoId = extractVideoId(url);
    if (videoId == null) {
      throw Exception('Invalid YouTube URL: Unable to extract video ID');
    }

    try {
      // Try to get data from YouTube API first
      final apiData = await _apiClient.getVideoData(videoId);
      
      if (apiData != null) {
        return _createContentFromApiData(url, apiData);
      }
    } catch (e) {
      // If API fails (quota exceeded, network error, etc.), fallback to web scraping
      print('YouTube API failed: $e. Falling back to web scraping.');
    }

    // Fallback to web scraping
    final metadata = await _metadataExtractor.extractMetadata(
      url: url,
      platform: 'youtube',
    );

    return _createContentFromMetadata(url, metadata, videoId);
  }

  Content _createContentFromApiData(String url, YouTubeVideoData apiData) {
    final now = DateTime.now();
    final contentId = _uuid.v4();
    
    // Parse timestamps from description
    final timestamps = _parseTimestamps(apiData.description);
    
    // Prepare metadata
    final metadata = {
      ...apiData.toJson(),
      'timestamps': timestamps,
    };

    return Content(
      id: contentId,
      title: apiData.title,
      url: url,
      description: _truncateDescription(apiData.description),
      thumbnailUrl: apiData.thumbnailUrl,
      contentType: 'youtube',
      sourcePlatform: 'youtube',
      author: apiData.channelTitle,
      publishedAt: apiData.publishedAt,
      contentText: apiData.description,
      metadata: jsonEncode(metadata),
      isFavorite: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Content _createContentFromMetadata(
    String url,
    ContentMetadata metadata,
    String videoId,
  ) {
    final now = DateTime.now();
    final contentId = _uuid.v4();

    final metadataJson = {
      'videoId': videoId,
      'platform': 'youtube',
      if (metadata.additionalData.isNotEmpty) ...metadata.additionalData,
    };

    return Content(
      id: contentId,
      title: metadata.title ?? 'YouTube Video',
      url: url,
      description: metadata.description,
      thumbnailUrl: metadata.thumbnailUrl,
      contentType: 'youtube',
      sourcePlatform: 'youtube',
      author: metadata.author,
      publishedAt: metadata.publishedAt,
      contentText: metadata.contentText,
      metadata: jsonEncode(metadataJson),
      isFavorite: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _truncateDescription(String description) {
    const maxLength = 500;
    if (description.length <= maxLength) {
      return description;
    }
    return '${description.substring(0, maxLength)}...';
  }

  List<Map<String, String>> _parseTimestamps(String description) {
    final timestamps = <Map<String, String>>[];
    
    // Common timestamp patterns
    final patterns = [
      // 0:00, 00:00, 0:00:00, 00:00:00
      RegExp(r'(\d{1,2}:\d{2}(?::\d{2})?)\s*[-–—]?\s*(.+?)(?=\n|\d{1,2}:\d{2}|$)'),
      // [0:00], [00:00], etc.
      RegExp(r'\[(\d{1,2}:\d{2}(?::\d{2})?)\]\s*[-–—]?\s*(.+?)(?=\n|\[?\d{1,2}:\d{2}|$)'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(description);
      if (matches.isNotEmpty) {
        for (final match in matches) {
          if (match.groupCount >= 2) {
            final time = match.group(1)?.trim() ?? '';
            final title = match.group(2)?.trim() ?? '';
            if (time.isNotEmpty && title.isNotEmpty) {
              timestamps.add({
                'time': time,
                'title': title,
              });
            }
          }
        }
        break; // Use the first pattern that matches
      }
    }

    return timestamps;
  }
}