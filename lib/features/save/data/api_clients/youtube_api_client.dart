import 'dart:convert';
import 'package:dio/dio.dart';

class YouTubeVideoData {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String channelId;
  final DateTime? publishedAt;
  final Duration? duration;
  final int viewCount;
  final int likeCount;
  final bool hasSubtitles;
  final List<String> tags;

  YouTubeVideoData({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.channelId,
    this.publishedAt,
    this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.hasSubtitles,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
    'videoId': id,
    'channelTitle': channelTitle,
    'channelId': channelId,
    'publishedAt': publishedAt?.toIso8601String(),
    'duration': duration?.inSeconds,
    'viewCount': viewCount,
    'likeCount': likeCount,
    'hasSubtitles': hasSubtitles,
    'tags': tags,
  };
}

class YouTubeApiClient {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int _quotaLimit = 10000;
  static const int _timeout = 5000; // 5 seconds
  
  final String apiKey;
  final Dio _dio;
  int _quotaUsed = 0;
  DateTime _quotaResetDate = DateTime.now();

  YouTubeApiClient({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: Duration(milliseconds: _timeout),
          receiveTimeout: Duration(milliseconds: _timeout),
        ));

  bool get isQuotaExceeded {
    // Reset quota counter if it's a new day
    if (DateTime.now().day != _quotaResetDate.day) {
      _quotaUsed = 0;
      _quotaResetDate = DateTime.now();
    }
    return _quotaUsed >= _quotaLimit;
  }

  Future<YouTubeVideoData?> getVideoData(String videoId) async {
    if (isQuotaExceeded) {
      throw Exception('YouTube API quota exceeded for today');
    }

    try {
      // API call costs 1 unit for videos endpoint + 2 units for snippet,contentDetails,statistics
      _quotaUsed += 3;

      final response = await _dio.get(
        '/videos',
        queryParameters: {
          'part': 'snippet,contentDetails,statistics',
          'id': videoId,
          'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['items'] != null && data['items'].isNotEmpty) {
          final videoData = data['items'][0];
          final snippet = videoData['snippet'];
          final contentDetails = videoData['contentDetails'];
          final statistics = videoData['statistics'];

          return YouTubeVideoData(
            id: videoId,
            title: snippet['title'] ?? '',
            description: snippet['description'] ?? '',
            thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
            channelTitle: snippet['channelTitle'] ?? '',
            channelId: snippet['channelId'] ?? '',
            publishedAt: snippet['publishedAt'] != null
                ? DateTime.parse(snippet['publishedAt'])
                : null,
            duration: _parseDuration(contentDetails['duration']),
            viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
            likeCount: int.tryParse(statistics['likeCount'] ?? '0') ?? 0,
            hasSubtitles: _checkSubtitles(contentDetails),
            tags: List<String>.from(snippet['tags'] ?? []),
          );
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('YouTube API timeout');
      } else if (e.response?.statusCode == 403) {
        throw Exception('YouTube API key invalid or quota exceeded');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Video not found or is private');
      }
      throw Exception('YouTube API error: ${e.message}');
    }
    
    return null;
  }

  String _getBestThumbnail(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return '';
    
    // Priority: maxres > standard > high > medium > default
    final priorities = ['maxres', 'standard', 'high', 'medium', 'default'];
    
    for (final priority in priorities) {
      if (thumbnails[priority] != null && thumbnails[priority]['url'] != null) {
        return thumbnails[priority]['url'];
      }
    }
    
    return '';
  }

  Duration? _parseDuration(String? isoDuration) {
    if (isoDuration == null) return null;
    
    // Parse ISO 8601 duration format (e.g., PT4M13S)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    
    return null;
  }

  bool _checkSubtitles(Map<String, dynamic> contentDetails) {
    // Check if captions are available
    return contentDetails['caption'] == 'true';
  }

  void dispose() {
    _dio.close();
  }
}