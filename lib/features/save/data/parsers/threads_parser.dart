import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/services/content_metadata_extractor.dart';
import '../models/threads_post_model.dart';

class ThreadsParser {
  final ContentMetadataExtractor _metadataExtractor;
  final http.Client _httpClient;
  final _uuid = const Uuid();
  
  // Optional session cookie for authenticated requests
  final String? _sessionCookie;
  
  // Constants
  static const int _maxThreadDepth = 50;
  static const int _maxMediaPerPost = 10;
  static const int _maxTextLength = 500;
  static const Duration _requestTimeout = Duration(seconds: 15);

  ThreadsParser({
    required ContentMetadataExtractor metadataExtractor,
    String? sessionCookie,
    http.Client? httpClient,
  }) : _metadataExtractor = metadataExtractor,
       _sessionCookie = sessionCookie,
       _httpClient = httpClient ?? http.Client();

  // Threads URL patterns
  static const _threadsUrlPatterns = [
    r'(?:https?:\/\/)?(?:www\.)?threads\.net\/(@[\w.]+)\/post\/([\w-]+)',
    r'(?:https?:\/\/)?(?:www\.)?threads\.net\/t\/([\w-]+)',
  ];

  bool canParse(String url) {
    for (final pattern in _threadsUrlPatterns) {
      if (RegExp(pattern).hasMatch(url)) {
        return true;
      }
    }
    return false;
  }

  Map<String, String>? extractPostInfo(String url) {
    for (final pattern in _threadsUrlPatterns) {
      final match = RegExp(pattern).firstMatch(url);
      if (match != null) {
        if (match.groupCount >= 2) {
          return {
            'username': match.group(1)!,
            'postId': match.group(2)!,
          };
        } else if (match.groupCount >= 1) {
          return {
            'postId': match.group(1)!,
          };
        }
      }
    }
    return null;
  }

  Future<Content> parse(String url) async {
    debugPrint('ThreadsParser: Parsing URL: $url');
    
    // Clean and normalize the URL
    url = url.trim();
    if (url.contains('threads.net') && !url.startsWith('http')) {
      url = 'https://$url';
      debugPrint('ThreadsParser: Normalized URL to: $url');
    }
    
    final postInfo = extractPostInfo(url);
    if (postInfo == null || postInfo['postId'] == null) {
      debugPrint('ThreadsParser: Could not extract post info from URL: $url');
      throw Exception('Invalid Threads URL: Unable to extract post ID from $url');
    }
    
    debugPrint('ThreadsParser: Extracted post info: $postInfo');

    try {
      // Try GraphQL API approach first
      final graphqlData = await _fetchFromGraphQL(postInfo['postId']!);
      if (graphqlData != null) {
        return _createContentFromThreadsData(url, graphqlData);
      }
    } catch (e) {
      debugPrint('ThreadsParser: GraphQL failed: $e. Falling back to web scraping.');
    }

    // Fallback to web scraping
    final scrapedData = await _parseFromWebScraping(url);
    if (scrapedData != null) {
      return _createContentFromThreadsData(url, scrapedData);
    }

    // Final fallback to metadata extraction
    final metadata = await _metadataExtractor.extractMetadata(
      url: url,
      platform: 'threads',
    );

    return _createContentFromMetadata(url, metadata, postInfo['postId']!);
  }

  Future<ThreadsConversationModel?> _fetchFromGraphQL(String postId) async {
    try {
      // Threads uses Instagram's GraphQL infrastructure
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
        'X-IG-App-ID': '238260118697367', // Threads Web App ID
      };
      
      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // First, get the post data
      final postResponse = await _httpClient.get(
        Uri.parse('https://www.threads.net/api/graphql'),
        headers: headers,
      ).timeout(_requestTimeout);

      if (postResponse.statusCode != 200) {
        return null;
      }

      // Parse response and extract post data
      // Note: This is a simplified version. Real implementation would need proper GraphQL query
      final postData = jsonDecode(postResponse.body);
      
      // For now, return null to trigger web scraping fallback
      return null;
    } catch (e) {
      debugPrint('ThreadsParser: GraphQL error: $e');
      return null;
    }
  }

  Future<ThreadsConversationModel?> _parseFromWebScraping(String url) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      };
      
      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(_requestTimeout);

      if (response.statusCode == 403) {
        throw Exception('Access denied. Post may be private or region-restricted.');
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limited. Please try again later.');
      }

      if (response.statusCode != 200) {
        return null;
      }

      final document = html_parser.parse(response.body);
      
      // Extract structured data
      final scriptTags = document.querySelectorAll('script[type="application/ld+json"]');
      Map<String, dynamic>? structuredData;
      
      for (final script in scriptTags) {
        try {
          final data = jsonDecode(script.text);
          if (data['@type'] == 'SocialMediaPosting' || 
              data['@type'] == 'Article' ||
              data['@type'] == 'BlogPosting') {
            structuredData = data;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      // Extract post content
      final postText = _extractPostText(document, structuredData);
      final authorInfo = _extractAuthorInfo(document, structuredData);
      final mediaAssets = _extractMediaAssets(document);
      final publishedDate = _extractPublishedDate(document, structuredData);
      final mentions = _extractMentions(postText ?? '');
      final hashtags = _extractHashtags(postText ?? '');

      if (postText == null || authorInfo == null) {
        return null;
      }

      final postId = extractPostInfo(url)?['postId'] ?? _uuid.v4();
      
      final post = ThreadsPostModel(
        id: postId,
        text: postText,
        authorId: authorInfo['id'] ?? authorInfo['username']!,
        authorUsername: authorInfo['username']!,
        authorName: authorInfo['name'] ?? authorInfo['username']!,
        authorProfileImageUrl: authorInfo['profileImageUrl'],
        createdAt: publishedDate ?? DateTime.now(),
        mediaAssets: mediaAssets,
        mediaUrls: mediaAssets.map((m) => m.url).toList(),
        mentions: mentions,
        hashtags: hashtags,
        additionalData: {
          'source': 'web_scraping',
          'scraped_at': DateTime.now().toIso8601String(),
        },
      );

      // Check if this is part of a conversation
      final conversationPosts = await _extractConversationPosts(document, post);
      
      return ThreadsConversationModel(
        conversationId: postId,
        authorId: authorInfo['id'] ?? authorInfo['username']!,
        authorUsername: authorInfo['username']!,
        authorName: authorInfo['name'] ?? authorInfo['username']!,
        authorProfileImageUrl: authorInfo['profileImageUrl'],
        posts: conversationPosts,
        conversationStartedAt: conversationPosts.first.createdAt,
        conversationLastUpdatedAt: conversationPosts.last.createdAt,
        isComplete: conversationPosts.length < _maxThreadDepth,
      );
    } catch (e) {
      debugPrint('ThreadsParser: Web scraping error: $e');
      return null;
    }
  }

  String? _extractPostText(document, Map<String, dynamic>? structuredData) {
    // Try structured data first
    if (structuredData != null) {
      final text = structuredData['text'] ?? 
                   structuredData['articleBody'] ?? 
                   structuredData['description'];
      if (text != null) return text.toString().trim();
    }

    // Try meta tags
    final metaSelectors = [
      'meta[property="og:description"]',
      'meta[name="description"]',
      'meta[property="twitter:description"]',
    ];

    for (final selector in metaSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
    }

    // Try content selectors
    final contentSelectors = [
      'div[data-testid="post-content"]',
      'div[role="article"] span[dir="auto"]',
      'div.post-content',
      'article div[dir="auto"]',
    ];

    for (final selector in contentSelectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final texts = elements
            .map((e) => e.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (texts.isNotEmpty) {
          return texts.join('\n').trim();
        }
      }
    }

    return null;
  }

  Map<String, String>? _extractAuthorInfo(document, Map<String, dynamic>? structuredData) {
    final info = <String, String>{};

    // Try structured data
    if (structuredData != null && structuredData['author'] != null) {
      final author = structuredData['author'];
      info['name'] = author['name']?.toString() ?? '';
      info['username'] = author['alternateName']?.toString() ?? 
                        author['identifier']?.toString() ?? '';
      info['profileImageUrl'] = author['image']?.toString() ?? '';
    }

    // Try meta tags
    final titleMeta = document.querySelector('meta[property="og:title"]');
    if (titleMeta != null) {
      final title = titleMeta.attributes['content'];
      if (title != null && title.contains(' (@')) {
        final match = RegExp(r'(.+) \(@([\w.]+)\)').firstMatch(title);
        if (match != null) {
          info['name'] = match.group(1)!.trim();
          info['username'] = '@${match.group(2)}';
        }
      }
    }

    // Extract from URL if needed
    if (info['username'] == null || info['username']!.isEmpty) {
      final urlMeta = document.querySelector('meta[property="og:url"]');
      if (urlMeta != null) {
        final url = urlMeta.attributes['content'];
        if (url != null) {
          final match = RegExp(r'threads\.net/(@[\w.]+)').firstMatch(url);
          if (match != null) {
            info['username'] = match.group(1)!;
          }
        }
      }
    }

    return info.isNotEmpty ? info : null;
  }

  List<MediaAsset> _extractMediaAssets(document) {
    final assets = <MediaAsset>[];
    
    // Extract images
    final imageMeta = document.querySelector('meta[property="og:image"]');
    if (imageMeta != null) {
      final imageUrl = imageMeta.attributes['content'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        assets.add(MediaAsset(
          url: imageUrl,
          type: 'image',
          metadata: {'source': 'og:image'},
        ));
      }
    }

    // Extract from img tags
    final imgSelectors = [
      'img[src*="cdninstagram.com"]',
      'img[src*="threads.net"]',
      'article img[alt]',
      'div[role="button"] img',
    ];

    for (final selector in imgSelectors) {
      final images = document.querySelectorAll(selector);
      for (final img in images) {
        if (assets.length >= _maxMediaPerPost) break;
        
        final src = img.attributes['src'] ?? img.attributes['data-src'];
        if (src != null && !assets.any((a) => a.url == src)) {
          assets.add(MediaAsset(
            url: src,
            type: 'image',
            altText: img.attributes['alt'],
            metadata: {'source': 'img_tag'},
          ));
        }
      }
    }

    // Extract videos
    final videoSelectors = [
      'video source',
      'video[src]',
    ];

    for (final selector in videoSelectors) {
      final videos = document.querySelectorAll(selector);
      for (final video in videos) {
        if (assets.length >= _maxMediaPerPost) break;
        
        final src = video.attributes['src'];
        if (src != null && !assets.any((a) => a.url == src)) {
          assets.add(MediaAsset(
            url: src,
            type: 'video',
            thumbnailUrl: video.attributes['poster'],
            metadata: {'source': 'video_tag'},
          ));
        }
      }
    }

    return assets;
  }

  DateTime? _extractPublishedDate(document, Map<String, dynamic>? structuredData) {
    // Try structured data
    if (structuredData != null) {
      final dateStr = structuredData['datePublished'] ?? 
                     structuredData['dateCreated'] ?? 
                     structuredData['dateModified'];
      if (dateStr != null) {
        try {
          return DateTime.parse(dateStr.toString());
        } catch (e) {
          // Continue to other methods
        }
      }
    }

    // Try time element
    final timeElements = document.querySelectorAll('time[datetime]');
    for (final time in timeElements) {
      final datetime = time.attributes['datetime'];
      if (datetime != null) {
        try {
          return DateTime.parse(datetime);
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  List<String> _extractMentions(String text) {
    final mentions = <String>[];
    final mentionPattern = RegExp(r'@([\w.]+)');
    final matches = mentionPattern.allMatches(text);
    
    for (final match in matches) {
      if (match.groupCount >= 1) {
        final mention = '@${match.group(1)}';
        if (!mentions.contains(mention)) {
          mentions.add(mention);
        }
      }
    }
    
    return mentions;
  }

  List<String> _extractHashtags(String text) {
    final hashtags = <String>[];
    final hashtagPattern = RegExp(r'#(\w+)');
    final matches = hashtagPattern.allMatches(text);
    
    for (final match in matches) {
      if (match.groupCount >= 1) {
        final hashtag = '#${match.group(1)}';
        if (!hashtags.contains(hashtag)) {
          hashtags.add(hashtag);
        }
      }
    }
    
    return hashtags;
  }

  Future<List<ThreadsPostModel>> _extractConversationPosts(
    document,
    ThreadsPostModel mainPost,
  ) async {
    final posts = [mainPost];
    
    // Look for reply chain or conversation structure
    // This is simplified - real implementation would need more sophisticated parsing
    final replySelectors = [
      'div[data-testid="reply"]',
      'article[role="article"]',
      'div.reply-container',
    ];

    for (final selector in replySelectors) {
      final replies = document.querySelectorAll(selector);
      for (final reply in replies) {
        if (posts.length >= _maxThreadDepth) break;
        
        // Extract reply content (simplified)
        final replyText = reply.text.trim();
        if (replyText.isNotEmpty && replyText != mainPost.text) {
          // This is a simplified version - would need proper parsing
          posts.add(ThreadsPostModel(
            id: _uuid.v4(),
            text: replyText,
            authorId: mainPost.authorId,
            authorUsername: mainPost.authorUsername,
            authorName: mainPost.authorName,
            authorProfileImageUrl: mainPost.authorProfileImageUrl,
            createdAt: mainPost.createdAt,
            inReplyToId: posts.last.id,
          ));
        }
      }
    }

    return posts;
  }

  Content _createContentFromThreadsData(String url, ThreadsConversationModel conversation) {
    final now = DateTime.now();
    final contentId = _uuid.v4();
    
    // Combine all posts text
    final fullText = conversation.posts
        .map((post) => post.text)
        .join('\n\n---\n\n');
    
    // Get all media URLs
    final allMediaUrls = conversation.posts
        .expand((post) => post.mediaUrls ?? [])
        .toList();
    
    // Prepare metadata
    final metadata = {
      'conversationId': conversation.conversationId,
      'postCount': conversation.posts.length,
      'posts': conversation.posts.map((p) => p.toJson()).toList(),
      'mediaUrls': allMediaUrls,
      'mentions': conversation.posts.expand((p) => p.mentions ?? []).toSet().toList(),
      'hashtags': conversation.posts.expand((p) => p.hashtags ?? []).toSet().toList(),
    };

    // Truncate text if needed
    final truncatedText = fullText.length > _maxTextLength 
        ? '${fullText.substring(0, _maxTextLength)}...' 
        : fullText;

    return Content(
      id: contentId,
      title: _generateTitle(conversation),
      url: url,
      description: _truncateText(conversation.posts.first.text),
      thumbnailUrl: allMediaUrls.isNotEmpty ? allMediaUrls.first : null,
      contentType: 'threads',
      sourcePlatform: 'threads',
      author: conversation.authorUsername,
      publishedAt: conversation.posts.first.createdAt,
      contentText: truncatedText,
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
    String postId,
  ) {
    final now = DateTime.now();
    final contentId = _uuid.v4();

    final metadataJson = {
      'postId': postId,
      'platform': 'threads',
      if (metadata.additionalData.isNotEmpty) ...metadata.additionalData,
    };

    return Content(
      id: contentId,
      title: metadata.title ?? 'Threads Post',
      url: url,
      description: metadata.description,
      thumbnailUrl: metadata.thumbnailUrl,
      contentType: 'threads',
      sourcePlatform: 'threads',
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

  String _generateTitle(ThreadsConversationModel conversation) {
    final firstPost = conversation.posts.first;
    final truncatedText = _truncateText(firstPost.text, maxLength: 50);
    
    if (conversation.posts.length > 1) {
      return '$truncatedText (Thread - ${conversation.posts.length} posts)';
    } else {
      return truncatedText;
    }
  }

  String _truncateText(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  void dispose() {
    _httpClient.close();
  }
}