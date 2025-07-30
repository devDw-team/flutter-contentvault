import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/services/content_metadata_extractor.dart';
import '../models/tweet_model.dart';
import '../models/twitter_thread_model.dart';

class TwitterParser {
  final ContentMetadataExtractor _metadataExtractor;
  final http.Client _httpClient;
  final _uuid = const Uuid();
  
  // Twitter API Bearer Token (optional)
  final String? _bearerToken;
  
  // Constants
  static const int _maxThreadLength = 100;
  static const Duration _requestTimeout = Duration(seconds: 10);

  TwitterParser({
    required ContentMetadataExtractor metadataExtractor,
    String? bearerToken,
    http.Client? httpClient,
  }) : _metadataExtractor = metadataExtractor,
       _bearerToken = bearerToken,
       _httpClient = httpClient ?? http.Client();

  static const _twitterUrlPatterns = [
    r'(?:https?:\/\/)?(?:www\.)?twitter\.com\/(?:\w+)\/status\/(\d+)',
    r'(?:https?:\/\/)?(?:www\.)?x\.com\/(?:\w+)\/status\/(\d+)',
    r'(?:https?:\/\/)?(?:mobile\.)?twitter\.com\/(?:\w+)\/status\/(\d+)',
    r'(?:https?:\/\/)?(?:mobile\.)?x\.com\/(?:\w+)\/status\/(\d+)',
  ];

  bool canParse(String url) {
    for (final pattern in _twitterUrlPatterns) {
      if (RegExp(pattern).hasMatch(url)) {
        return true;
      }
    }
    return false;
  }

  String? extractTweetId(String url) {
    for (final pattern in _twitterUrlPatterns) {
      final match = RegExp(pattern).firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  Future<Content> parse(String url) async {
    final tweetId = extractTweetId(url);
    if (tweetId == null) {
      throw Exception('Invalid Twitter/X URL: Unable to extract tweet ID');
    }

    try {
      // Try Twitter API v2 if bearer token is available
      if (_bearerToken != null && _bearerToken!.isNotEmpty) {
        final apiData = await _fetchFromTwitterApi(tweetId);
        if (apiData != null) {
          return _createContentFromApiData(url, apiData);
        }
      }
    } catch (e) {
      print('Twitter API failed: $e. Falling back to web scraping.');
    }

    // Fallback to web scraping
    final threadData = await _parseThreadFromWebScraping(url);
    if (threadData != null) {
      return _createContentFromApiData(url, threadData);
    }

    // If all else fails, use basic metadata extraction
    final metadata = await _metadataExtractor.extractMetadata(
      url: url,
      platform: 'twitter',
    );

    return _createContentFromMetadata(url, metadata, tweetId);
  }

  Future<TwitterThreadModel?> _fetchFromTwitterApi(String tweetId) async {
    if (_bearerToken == null || _bearerToken!.isEmpty) {
      return null;
    }

    try {
      // Get tweet with conversation_id
      final tweetResponse = await _httpClient.get(
        Uri.parse('https://api.twitter.com/2/tweets/$tweetId?tweet.fields=conversation_id,author_id,created_at,text,public_metrics,referenced_tweets&expansions=author_id,referenced_tweets.id&user.fields=name,username,profile_image_url'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
        },
      ).timeout(_requestTimeout);

      if (tweetResponse.statusCode != 200) {
        print('Twitter API error: ${tweetResponse.statusCode}');
        return null;
      }

      final tweetData = jsonDecode(tweetResponse.body);
      final tweet = tweetData['data'];
      final conversationId = tweet['conversation_id'];
      final authorData = (tweetData['includes']['users'] as List).first;

      // Get thread tweets
      final threadResponse = await _httpClient.get(
        Uri.parse('https://api.twitter.com/2/tweets/search/recent?query=conversation_id:$conversationId&tweet.fields=in_reply_to_user_id,author_id,created_at,text,public_metrics&max_results=$_maxThreadLength&expansions=author_id'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
        },
      ).timeout(_requestTimeout);

      if (threadResponse.statusCode != 200) {
        // If thread search fails, return single tweet
        return _createThreadFromSingleTweet(tweet, authorData);
      }

      final threadData = jsonDecode(threadResponse.body);
      final tweets = threadData['data'] as List;

      // Filter and sort tweets by the same author
      final authorTweets = tweets
          .where((t) => t['author_id'] == tweet['author_id'])
          .toList()
        ..sort((a, b) => DateTime.parse(a['created_at'])
            .compareTo(DateTime.parse(b['created_at'])));

      return _createThreadFromApiData(authorTweets, authorData, conversationId);
    } catch (e) {
      print('Error fetching from Twitter API: $e');
      return null;
    }
  }

  TwitterThreadModel _createThreadFromApiData(
    List<dynamic> tweets,
    Map<String, dynamic> authorData,
    String conversationId,
  ) {
    final tweetModels = tweets.map((tweetJson) {
      return TweetModel(
        id: tweetJson['id'],
        text: tweetJson['text'],
        authorId: tweetJson['author_id'],
        authorUsername: authorData['username'],
        authorName: authorData['name'],
        authorProfileImageUrl: authorData['profile_image_url'],
        createdAt: DateTime.parse(tweetJson['created_at']),
        replyCount: tweetJson['public_metrics']?['reply_count'],
        retweetCount: tweetJson['public_metrics']?['retweet_count'],
        likeCount: tweetJson['public_metrics']?['like_count'],
        inReplyToStatusId: tweetJson['in_reply_to_user_id'],
      );
    }).toList();

    return TwitterThreadModel(
      threadId: conversationId,
      conversationId: conversationId,
      authorId: authorData['id'],
      authorUsername: authorData['username'],
      authorName: authorData['name'],
      authorProfileImageUrl: authorData['profile_image_url'],
      tweets: tweetModels,
      threadStartedAt: tweetModels.first.createdAt,
      threadLastUpdatedAt: tweetModels.last.createdAt,
      isComplete: tweets.length < _maxThreadLength,
    );
  }

  TwitterThreadModel _createThreadFromSingleTweet(
    Map<String, dynamic> tweet,
    Map<String, dynamic> authorData,
  ) {
    final tweetModel = TweetModel(
      id: tweet['id'],
      text: tweet['text'],
      authorId: tweet['author_id'],
      authorUsername: authorData['username'],
      authorName: authorData['name'],
      authorProfileImageUrl: authorData['profile_image_url'],
      createdAt: DateTime.parse(tweet['created_at']),
      replyCount: tweet['public_metrics']?['reply_count'],
      retweetCount: tweet['public_metrics']?['retweet_count'],
      likeCount: tweet['public_metrics']?['like_count'],
    );

    return TwitterThreadModel(
      threadId: tweet['conversation_id'],
      conversationId: tweet['conversation_id'],
      authorId: authorData['id'],
      authorUsername: authorData['username'],
      authorName: authorData['name'],
      authorProfileImageUrl: authorData['profile_image_url'],
      tweets: [tweetModel],
      threadStartedAt: tweetModel.createdAt,
      isComplete: true,
    );
  }

  Content _createContentFromApiData(String url, TwitterThreadModel threadData) {
    final now = DateTime.now();
    final contentId = _uuid.v4();
    
    // Combine thread text
    final fullText = threadData.tweets
        .map((tweet) => tweet.text)
        .join('\n\n---\n\n');
    
    // Get all media URLs
    final allMediaUrls = threadData.tweets
        .expand((tweet) => tweet.mediaUrls)
        .toList();
    
    // Prepare metadata
    final metadata = {
      'threadId': threadData.threadId,
      'conversationId': threadData.conversationId,
      'tweetCount': threadData.tweets.length,
      'tweets': threadData.tweets.map((t) => t.toJson()).toList(),
      'mediaUrls': allMediaUrls,
      'hasQuotedTweets': threadData.tweets.any((t) => t.quotedTweetId != null),
    };

    return Content(
      id: contentId,
      title: _generateTitle(threadData),
      url: url,
      description: _truncateText(threadData.tweets.first.text),
      thumbnailUrl: allMediaUrls.isNotEmpty ? allMediaUrls.first : null,
      contentType: 'twitter',
      sourcePlatform: 'twitter',
      author: threadData.authorUsername,
      publishedAt: threadData.tweets.first.createdAt,
      contentText: fullText,
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
    String tweetId,
  ) {
    final now = DateTime.now();
    final contentId = _uuid.v4();

    final metadataJson = {
      'tweetId': tweetId,
      'platform': 'twitter',
      if (metadata.additionalData.isNotEmpty) ...metadata.additionalData,
    };

    return Content(
      id: contentId,
      title: metadata.title ?? 'Twitter/X Post',
      url: url,
      description: metadata.description,
      thumbnailUrl: metadata.thumbnailUrl,
      contentType: 'twitter',
      sourcePlatform: 'twitter',
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

  String _generateTitle(TwitterThreadModel thread) {
    final firstTweet = thread.tweets.first;
    final truncatedText = _truncateText(firstTweet.text, maxLength: 50);
    
    if (thread.tweets.length > 1) {
      return '$truncatedText (Thread - ${thread.tweets.length} tweets)';
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

  // Parse thread from web scraping results
  Future<TwitterThreadModel?> _parseThreadFromWebScraping(String url) async {
    try {
      // First, try to get the tweet page
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final document = html_parser.parse(response.body);
      
      // Extract tweet data from meta tags and structured data
      final tweetText = _extractTweetText(document);
      final authorName = _extractAuthorName(document);
      final authorUsername = _extractAuthorUsername(document);
      final publishedDate = _extractPublishedDate(document);
      final mediaUrls = _extractMediaUrls(document);

      if (tweetText == null || authorUsername == null) {
        return null;
      }

      // Create a single tweet model from scraped data
      final tweetId = extractTweetId(url) ?? _uuid.v4();
      final tweetModel = TweetModel(
        id: tweetId,
        text: tweetText,
        authorId: authorUsername,
        authorUsername: authorUsername,
        authorName: authorName ?? authorUsername,
        createdAt: publishedDate ?? DateTime.now(),
        mediaUrls: mediaUrls,
      );

      // For web scraping, we can only get the single tweet reliably
      return TwitterThreadModel(
        threadId: tweetId,
        conversationId: tweetId,
        authorId: authorUsername,
        authorUsername: authorUsername,
        authorName: authorName ?? authorUsername,
        tweets: [tweetModel],
        threadStartedAt: tweetModel.createdAt,
        isComplete: true,
        additionalData: {
          'source': 'web_scraping',
          'scraped_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error during web scraping: $e');
      return null;
    }
  }

  String? _extractTweetText(document) {
    // Try multiple selectors for tweet text
    final selectors = [
      'meta[property="og:description"]',
      'meta[name="description"]',
      'div[data-testid="tweetText"]',
      'div[lang] span',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'] ?? element.text;
        if (content.isNotEmpty) {
          return content.trim();
        }
      }
    }
    return null;
  }

  String? _extractAuthorName(document) {
    final titleMeta = document.querySelector('meta[property="og:title"]');
    if (titleMeta != null) {
      final title = titleMeta.attributes['content'];
      if (title != null && title.contains(' on X:')) {
        return title.split(' on X:').first.trim();
      }
    }
    return null;
  }

  String? _extractAuthorUsername(document) {
    // Extract from URL or meta tags
    final urlMeta = document.querySelector('meta[property="og:url"]');
    if (urlMeta != null) {
      final url = urlMeta.attributes['content'];
      if (url != null) {
        final match = RegExp(r'/([\w]+)/status/').firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          return '@${match.group(1)}';
        }
      }
    }
    return null;
  }

  DateTime? _extractPublishedDate(document) {
    final timeMeta = document.querySelector('meta[name="twitter:data1"]');
    if (timeMeta != null) {
      final timeStr = timeMeta.attributes['content'];
      if (timeStr != null) {
        try {
          // Twitter uses various date formats
          return DateTime.parse(timeStr);
        } catch (e) {
          // Try parsing relative time (e.g., "2 hours ago")
          // For now, return null and use current time as fallback
        }
      }
    }
    return null;
  }

  List<String> _extractMediaUrls(document) {
    final mediaUrls = <String>[];
    
    // Extract from meta tags
    final imageMeta = document.querySelector('meta[property="og:image"]');
    if (imageMeta != null) {
      final imageUrl = imageMeta.attributes['content'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        mediaUrls.add(imageUrl);
      }
    }

    // Extract from img tags within tweet
    final images = document.querySelectorAll('img[src*="pbs.twimg.com/media"]');
    for (final img in images) {
      final src = img.attributes['src'];
      if (src != null && !mediaUrls.contains(src)) {
        mediaUrls.add(src);
      }
    }

    return mediaUrls;
  }

  void dispose() {
    _httpClient.close();
  }
}