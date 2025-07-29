import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class ContentMetadata {
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final String? author;
  final DateTime? publishedAt;
  final String? contentText;
  final Map<String, dynamic> additionalData;

  ContentMetadata({
    this.title,
    this.description,
    this.thumbnailUrl,
    this.author,
    this.publishedAt,
    this.contentText,
    this.additionalData = const {},
  });

  String toJson() => jsonEncode({
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'author': author,
        'publishedAt': publishedAt?.toIso8601String(),
        'contentText': contentText,
        ...additionalData,
      });
}

class ContentMetadataExtractor {
  final http.Client _httpClient;

  ContentMetadataExtractor({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<ContentMetadata> extractMetadata({
    required String url,
    required String platform,
  }) async {
    switch (platform) {
      case 'youtube':
        return _extractYouTubeMetadata(url);
      case 'twitter':
        return _extractTwitterMetadata(url);
      case 'threads':
        return _extractThreadsMetadata(url);
      case 'article':
        return _extractArticleMetadata(url);
      default:
        return _extractWebMetadata(url);
    }
  }

  Future<ContentMetadata> _extractYouTubeMetadata(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract YouTube specific metadata
        final title = document.querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        final description = document.querySelector('meta[property="og:description"]')
            ?.attributes['content'];
        final thumbnailUrl = document.querySelector('meta[property="og:image"]')
            ?.attributes['content'];
        final author = document.querySelector('span[itemprop="author"] link[itemprop="name"]')
            ?.attributes['content'];
        
        return ContentMetadata(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          author: author,
          additionalData: {
            'platform': 'youtube',
            'videoId': _extractYouTubeVideoId(url),
          },
        );
      }
    } catch (e) {
      // Fallback to basic metadata
    }
    
    return ContentMetadata(
      title: 'YouTube Video',
      additionalData: {'platform': 'youtube'},
    );
  }

  Future<ContentMetadata> _extractTwitterMetadata(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract Twitter/X specific metadata
        final title = document.querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        final description = document.querySelector('meta[property="og:description"]')
            ?.attributes['content'];
        final author = document.querySelector('meta[name="twitter:creator"]')
            ?.attributes['content'];
        
        return ContentMetadata(
          title: title ?? 'X Post',
          description: description,
          author: author,
          additionalData: {
            'platform': 'twitter',
          },
        );
      }
    } catch (e) {
      // Fallback to basic metadata
    }
    
    return ContentMetadata(
      title: 'X Post',
      additionalData: {'platform': 'twitter'},
    );
  }

  Future<ContentMetadata> _extractThreadsMetadata(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract Threads specific metadata
        final title = document.querySelector('meta[property="og:title"]')
            ?.attributes['content'] ?? 'Threads Post';
        final description = document.querySelector('meta[property="og:description"]')
            ?.attributes['content'];
        final thumbnailUrl = document.querySelector('meta[property="og:image"]')
            ?.attributes['content'];
        final author = document.querySelector('meta[name="twitter:title"]')
            ?.attributes['content']?.split('(@')?.last?.replaceAll(')', '');
        
        return ContentMetadata(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          author: author != null ? '@$author' : null,
          additionalData: {
            'platform': 'threads',
          },
        );
      }
    } catch (e) {
      // Fallback to basic metadata
    }
    
    return ContentMetadata(
      title: 'Threads Post',
      additionalData: {'platform': 'threads'},
    );
  }

  Future<ContentMetadata> _extractArticleMetadata(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract article metadata
        final title = document.querySelector('meta[property="og:title"]')
            ?.attributes['content'] ??
            document.querySelector('title')?.text;
        
        final description = document.querySelector('meta[property="og:description"]')
            ?.attributes['content'] ??
            document.querySelector('meta[name="description"]')?.attributes['content'];
        
        final thumbnailUrl = document.querySelector('meta[property="og:image"]')
            ?.attributes['content'];
        
        final author = document.querySelector('meta[name="author"]')
            ?.attributes['content'];
        
        // Extract main content text
        final article = document.querySelector('article') ?? 
                       document.querySelector('main') ??
                       document.querySelector('.content');
        
        String? contentText;
        if (article != null) {
          contentText = article.text.trim().substring(0, 5000); // Limit to 5000 chars
        }
        
        return ContentMetadata(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          author: author,
          contentText: contentText,
          additionalData: {
            'platform': 'article',
          },
        );
      }
    } catch (e) {
      // Fallback to basic metadata
    }
    
    return ContentMetadata(
      title: 'Article',
      additionalData: {'platform': 'article'},
    );
  }

  Future<ContentMetadata> _extractWebMetadata(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract general web metadata
        final title = document.querySelector('meta[property="og:title"]')
            ?.attributes['content'] ??
            document.querySelector('title')?.text;
        
        final description = document.querySelector('meta[property="og:description"]')
            ?.attributes['content'] ??
            document.querySelector('meta[name="description"]')?.attributes['content'];
        
        final thumbnailUrl = document.querySelector('meta[property="og:image"]')
            ?.attributes['content'];
        
        return ContentMetadata(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          additionalData: {
            'platform': 'web',
          },
        );
      }
    } catch (e) {
      // Fallback to basic metadata
    }
    
    return ContentMetadata(
      title: Uri.parse(url).host,
      additionalData: {'platform': 'web'},
    );
  }

  String? _extractYouTubeVideoId(String url) {
    final uri = Uri.parse(url);
    
    // youtube.com/watch?v=VIDEO_ID
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    
    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    
    return null;
  }

  void dispose() {
    _httpClient.close();
  }
}