import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../models/article_model.dart';

class WebParser {
  final _uuid = const Uuid();
  static const _maxHtmlSize = 10 * 1024 * 1024; // 10MB
  static const _defaultTimeout = Duration(seconds: 10);
  static const _defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  bool canParse(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  Future<ArticleModel> parse(String url, {String? userAgent}) async {
    final uri = Uri.parse(url);
    
    // Download HTML
    final response = await _downloadHtml(uri, userAgent: userAgent);
    
    // Parse HTML
    final document = html_parser.parse(response.body);
    
    // Extract metadata
    final metadata = _extractMetadata(document, uri);
    
    // Extract content using Readability algorithm
    final content = _extractContent(document);
    
    // Extract images
    final images = _extractImages(document, uri);
    
    // Calculate reading time
    final readingTime = _calculateReadingTime(content.text);
    
    return ArticleModel(
      id: _uuid.v4(),
      url: url,
      title: metadata['title'] ?? 'Untitled',
      author: metadata['author'],
      publishedAt: _parsePublishedDate(metadata['publishedAt']),
      description: metadata['description'],
      thumbnailUrl: metadata['thumbnailUrl'] ?? (images.isNotEmpty ? images.first : null),
      contentHtml: content.html,
      contentText: content.text,
      images: images,
      readingTimeMinutes: readingTime,
      metadata: metadata,
    );
  }

  Future<http.Response> _downloadHtml(Uri uri, {String? userAgent}) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers['User-Agent'] = userAgent ?? _defaultUserAgent;
      request.headers['Accept'] = 'text/html,application/xhtml+xml';
      request.headers['Accept-Language'] = 'en-US,en;q=0.9';
      
      final streamedResponse = await client.send(request).timeout(_defaultTimeout);
      
      if (streamedResponse.statusCode == 404 || streamedResponse.statusCode == 403) {
        throw Exception('Page not found or access denied: ${streamedResponse.statusCode}');
      }
      
      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to load page: ${streamedResponse.statusCode}');
      }
      
      // Check content length
      final contentLength = streamedResponse.contentLength;
      if (contentLength != null && contentLength > _maxHtmlSize) {
        throw Exception('HTML too large: ${contentLength} bytes');
      }
      
      final response = await http.Response.fromStream(streamedResponse);
      
      // Force UTF-8 encoding if necessary
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('charset')) {
        return http.Response(
          utf8.decode(response.bodyBytes),
          response.statusCode,
          headers: response.headers,
        );
      }
      
      return response;
    } finally {
      client.close();
    }
  }

  Map<String, String?> _extractMetadata(Document document, Uri uri) {
    final metadata = <String, String?>{};
    
    // Title
    metadata['title'] = _getMetaContent(document, 'og:title') ??
        _getMetaContent(document, 'twitter:title') ??
        document.querySelector('title')?.text ??
        document.querySelector('h1')?.text;
    
    // Description
    metadata['description'] = _getMetaContent(document, 'og:description') ??
        _getMetaContent(document, 'twitter:description') ??
        _getMetaContent(document, 'description');
    
    // Author
    metadata['author'] = _getMetaContent(document, 'author') ??
        _getMetaContent(document, 'article:author') ??
        document.querySelector('[rel="author"]')?.text;
    
    // Published date
    metadata['publishedAt'] = _getMetaContent(document, 'article:published_time') ??
        _getMetaContent(document, 'datePublished') ??
        document.querySelector('time[datetime]')?.attributes['datetime'];
    
    // Thumbnail
    metadata['thumbnailUrl'] = _getMetaContent(document, 'og:image') ??
        _getMetaContent(document, 'twitter:image');
    
    // Site name
    metadata['siteName'] = _getMetaContent(document, 'og:site_name') ??
        uri.host;
    
    return metadata;
  }

  String? _getMetaContent(Document document, String property) {
    return document.querySelector('meta[property="$property"]')?.attributes['content'] ??
        document.querySelector('meta[name="$property"]')?.attributes['content'];
  }

  _ContentResult _extractContent(Document document) {
    // Remove script and style elements
    document.querySelectorAll('script, style, noscript').forEach((element) {
      element.remove();
    });
    
    // Remove common ad/popup elements
    final adSelectors = [
      '.ad', '.ads', '.advertisement', '.popup', '.modal',
      '[class*="popup"]', '[class*="modal"]', '[class*="banner"]',
      '[id*="popup"]', '[id*="modal"]', '[id*="banner"]',
    ];
    
    for (final selector in adSelectors) {
      document.querySelectorAll(selector).forEach((element) {
        element.remove();
      });
    }
    
    // Find main content using Readability-like algorithm
    final contentElement = _findMainContent(document);
    
    if (contentElement == null) {
      return _ContentResult(
        html: document.body?.innerHtml ?? '',
        text: document.body?.text ?? '',
      );
    }
    
    // Clean up content
    _cleanContent(contentElement);
    
    return _ContentResult(
      html: contentElement.innerHtml,
      text: contentElement.text.trim(),
    );
  }

  Element? _findMainContent(Document document) {
    // Common content selectors
    final selectors = [
      'main', 'article', '[role="main"]', '[role="article"]',
      '.content', '.main-content', '.post-content', '.entry-content',
      '#content', '#main-content', '#post-content', '#entry-content',
    ];
    
    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null && element.text.trim().length > 100) {
        return element;
      }
    }
    
    // Score-based approach for finding content
    final candidates = <Element>[];
    final allElements = document.querySelectorAll('div, section, article');
    
    for (final element in allElements) {
      final score = _scoreElement(element);
      if (score > 0) {
        candidates.add(element);
      }
    }
    
    // Sort by score and text length
    candidates.sort((a, b) {
      final scoreA = _scoreElement(a);
      final scoreB = _scoreElement(b);
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return b.text.length.compareTo(a.text.length);
    });
    
    return candidates.isNotEmpty ? candidates.first : document.body;
  }

  int _scoreElement(Element element) {
    int score = 0;
    
    // Positive indicators
    if (element.localName == 'article') score += 30;
    if (element.localName == 'main') score += 25;
    
    final className = element.className.toLowerCase();
    final id = element.id.toLowerCase();
    
    // Positive class/id patterns
    final positivePatterns = ['content', 'article', 'main', 'post', 'text', 'body', 'entry'];
    for (final pattern in positivePatterns) {
      if (className.contains(pattern) || id.contains(pattern)) {
        score += 10;
      }
    }
    
    // Negative patterns
    final negativePatterns = ['sidebar', 'menu', 'nav', 'header', 'footer', 'ad', 'comment'];
    for (final pattern in negativePatterns) {
      if (className.contains(pattern) || id.contains(pattern)) {
        score -= 20;
      }
    }
    
    // Text density
    final textLength = element.text.length;
    final linkDensity = _calculateLinkDensity(element);
    
    if (textLength > 500) score += 20;
    if (linkDensity < 0.3) score += 10;
    
    // Paragraph count
    final paragraphs = element.querySelectorAll('p');
    score += paragraphs.length * 3;
    
    return score;
  }

  double _calculateLinkDensity(Element element) {
    final textLength = element.text.length;
    if (textLength == 0) return 0;
    
    int linkTextLength = 0;
    element.querySelectorAll('a').forEach((link) {
      linkTextLength += link.text.length;
    });
    
    return linkTextLength / textLength;
  }

  void _cleanContent(Element content) {
    // Remove empty elements
    content.querySelectorAll('*').forEach((element) {
      if (element.text.trim().isEmpty && 
          element.localName != 'img' && 
          element.localName != 'video' &&
          element.localName != 'iframe') {
        element.remove();
      }
    });
    
    // Remove attributes except essential ones
    content.querySelectorAll('*').forEach((element) {
      final keepAttributes = ['src', 'href', 'alt', 'title'];
      final attributes = element.attributes.keys.toList();
      for (final attr in attributes) {
        if (!keepAttributes.contains(attr)) {
          element.attributes.remove(attr);
        }
      }
    });
  }

  List<String> _extractImages(Document document, Uri baseUri) {
    final images = <String>[];
    final seen = <String>{};
    
    document.querySelectorAll('img').forEach((img) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final absoluteUrl = _makeAbsoluteUrl(src, baseUri);
        if (absoluteUrl != null && !seen.contains(absoluteUrl)) {
          images.add(absoluteUrl);
          seen.add(absoluteUrl);
        }
      }
    });
    
    return images;
  }

  String? _makeAbsoluteUrl(String url, Uri baseUri) {
    try {
      final uri = Uri.parse(url);
      if (uri.isAbsolute) {
        return url;
      }
      return baseUri.resolve(url).toString();
    } catch (e) {
      return null;
    }
  }

  int _calculateReadingTime(String text) {
    const wordsPerMinute = 200;
    final words = text.split(RegExp(r'\s+')).length;
    return (words / wordsPerMinute).ceil();
  }

  DateTime? _parsePublishedDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Future<Content> parseToContent(String url, {String? userAgent}) async {
    final article = await parse(url, userAgent: userAgent);
    final now = DateTime.now();
    
    final metadata = {
      'articleId': article.id,
      'images': article.images,
      'readingTimeMinutes': article.readingTimeMinutes,
      'contentHtml': article.contentHtml,
      ...article.metadata,
    };
    
    return Content(
      id: article.id,
      title: article.title,
      url: url,
      description: article.description,
      thumbnailUrl: article.thumbnailUrl,
      contentType: 'article',
      sourcePlatform: 'web',
      author: article.author,
      publishedAt: article.publishedAt,
      contentText: article.contentText,
      metadata: jsonEncode(metadata),
      isFavorite: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class _ContentResult {
  final String html;
  final String text;
  
  _ContentResult({required this.html, required this.text});
}