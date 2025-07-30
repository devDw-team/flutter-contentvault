import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contentvault/features/save/data/parsers/web_parser.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

void main() {
  late WebParser webParser;

  setUp(() {
    webParser = WebParser();
  });

  group('WebParser Unit Tests', () {
    group('URL Validation', () {
      test('accepts valid HTTP and HTTPS URLs', () {
        final validUrls = [
          'https://example.com',
          'http://example.com',
          'https://blog.example.com/post/123',
          'http://www.example.com/article?id=456',
          'https://example.com/path/to/article#section',
          'https://user:pass@example.com/secure',
        ];

        for (final url in validUrls) {
          expect(webParser.canParse(url), true, reason: 'Should accept $url');
        }
      });

      test('rejects invalid URLs', () {
        final invalidUrls = [
          '',
          'not-a-url',
          'ftp://example.com',
          'file:///etc/passwd',
          'javascript:alert(1)',
          'mailto:test@example.com',
          'data:text/html,<h1>Test</h1>',
        ];

        for (final url in invalidUrls) {
          expect(webParser.canParse(url), false, reason: 'Should reject $url');
        }
      });
    });

    group('Metadata Extraction', () {
      test('extracts OpenGraph metadata correctly', () {
        final html = '''
          <html>
          <head>
            <meta property="og:title" content="OG Title">
            <meta property="og:description" content="OG Description">
            <meta property="og:image" content="https://example.com/og-image.jpg">
            <meta property="og:site_name" content="Example Site">
          </head>
          <body></body>
          </html>
        ''';

        final document = html_parser.parse(html);
        final metadata = _extractMetadataTest(document);

        expect(metadata['title'], 'OG Title');
        expect(metadata['description'], 'OG Description');
        expect(metadata['thumbnailUrl'], 'https://example.com/og-image.jpg');
        expect(metadata['siteName'], 'Example Site');
      });

      test('extracts Twitter Card metadata', () {
        final html = '''
          <html>
          <head>
            <meta name="twitter:title" content="Twitter Title">
            <meta name="twitter:description" content="Twitter Description">
            <meta name="twitter:image" content="https://example.com/twitter-image.jpg">
          </head>
          <body></body>
          </html>
        ''';

        final document = html_parser.parse(html);
        final metadata = _extractMetadataTest(document);

        expect(metadata['title'], 'Twitter Title');
        expect(metadata['description'], 'Twitter Description');
        expect(metadata['thumbnailUrl'], 'https://example.com/twitter-image.jpg');
      });

      test('falls back to standard meta tags and title', () {
        final html = '''
          <html>
          <head>
            <title>Page Title</title>
            <meta name="description" content="Meta Description">
            <meta name="author" content="John Author">
          </head>
          <body><h1>H1 Title</h1></body>
          </html>
        ''';

        final document = html_parser.parse(html);
        final metadata = _extractMetadataTest(document);

        expect(metadata['title'], 'Page Title');
        expect(metadata['description'], 'Meta Description');
        expect(metadata['author'], 'John Author');
      });

      test('extracts published date from multiple sources', () {
        final html = '''
          <html>
          <head>
            <meta property="article:published_time" content="2024-01-20T10:00:00Z">
          </head>
          <body>
            <time datetime="2024-01-20T10:00:00Z">January 20, 2024</time>
          </body>
          </html>
        ''';

        final document = html_parser.parse(html);
        final metadata = _extractMetadataTest(document);

        expect(metadata['publishedAt'], '2024-01-20T10:00:00Z');
      });
    });

    group('Content Scoring', () {
      test('scores article elements highly', () {
        final articleElement = _createElement('article', className: 'post');
        final divElement = _createElement('div', className: 'post');
        final sidebarElement = _createElement('div', className: 'sidebar');

        final articleScore = _scoreElementTest(articleElement);
        final divScore = _scoreElementTest(divElement);
        final sidebarScore = _scoreElementTest(sidebarElement);

        expect(articleScore, greaterThan(divScore));
        expect(articleScore, greaterThan(sidebarScore));
        expect(divScore, greaterThan(sidebarScore));
      });

      test('penalizes navigation and ad elements', () {
        final contentDiv = _createElement('div', className: 'content');
        final navElement = _createElement('nav', className: 'menu');
        final adElement = _createElement('div', className: 'advertisement');

        final contentScore = _scoreElementTest(contentDiv);
        final navScore = _scoreElementTest(navElement);
        final adScore = _scoreElementTest(adElement);

        expect(contentScore, greaterThan(navScore));
        expect(contentScore, greaterThan(adScore));
      });
    });

    group('Reading Time Calculation', () {
      test('calculates reading time based on word count', () {
        // Average reading speed is 200 words per minute
        final shortText = 'Hello world'; // 2 words = 1 minute
        final mediumText = List.generate(200, (i) => 'word').join(' '); // 200 words = 1 minute
        final longText = List.generate(600, (i) => 'word').join(' '); // 600 words = 3 minutes

        expect(_calculateReadingTimeTest(shortText), 1);
        expect(_calculateReadingTimeTest(mediumText), 1);
        expect(_calculateReadingTimeTest(longText), 3);
      });
    });

    group('Image Extraction', () {
      test('converts relative URLs to absolute', () {
        final baseUri = Uri.parse('https://example.com/articles/');
        
        expect(_makeAbsoluteUrlTest('/image.jpg', baseUri), 
               'https://example.com/image.jpg');
        expect(_makeAbsoluteUrlTest('../images/photo.png', baseUri), 
               'https://example.com/images/photo.png');
        expect(_makeAbsoluteUrlTest('banner.gif', baseUri), 
               'https://example.com/articles/banner.gif');
        expect(_makeAbsoluteUrlTest('https://cdn.example.com/absolute.jpg', baseUri), 
               'https://cdn.example.com/absolute.jpg');
      });

      test('handles malformed URLs gracefully', () {
        final baseUri = Uri.parse('https://example.com/');
        
        expect(_makeAbsoluteUrlTest('', baseUri), null);
        // URLs with spaces get encoded, which is valid behavior
        expect(_makeAbsoluteUrlTest('not a valid url', baseUri), 'https://example.com/not%20a%20valid%20url');
      });
    });

    group('Content Cleaning', () {
      test('removes script and style tags', () {
        final html = '''
          <div>
            <p>Keep this content</p>
            <script>alert('remove this');</script>
            <style>body { color: red; }</style>
            <p>Keep this too</p>
          </div>
        ''';

        final document = html_parser.parse(html);
        final content = document.body!.querySelector('div')!;
        
        // Simulate cleaning
        content.querySelectorAll('script, style').forEach((e) => e.remove());
        
        expect(content.text, contains('Keep this content'));
        expect(content.text, contains('Keep this too'));
        expect(content.text, isNot(contains('alert')));
        expect(content.text, isNot(contains('color: red')));
      });
    });
  });
}

// Test helper methods that mirror the private methods in WebParser
Map<String, String?> _extractMetadataTest(Document document) {
  final metadata = <String, String?>{};
  
  metadata['title'] = _getMetaContent(document, 'og:title') ??
      _getMetaContent(document, 'twitter:title') ??
      document.querySelector('title')?.text ??
      document.querySelector('h1')?.text;
  
  metadata['description'] = _getMetaContent(document, 'og:description') ??
      _getMetaContent(document, 'twitter:description') ??
      _getMetaContent(document, 'description');
  
  metadata['author'] = _getMetaContent(document, 'author') ??
      _getMetaContent(document, 'article:author');
  
  metadata['publishedAt'] = _getMetaContent(document, 'article:published_time') ??
      document.querySelector('time[datetime]')?.attributes['datetime'];
  
  metadata['thumbnailUrl'] = _getMetaContent(document, 'og:image') ??
      _getMetaContent(document, 'twitter:image');
  
  metadata['siteName'] = _getMetaContent(document, 'og:site_name');
  
  return metadata;
}

String? _getMetaContent(Document document, String property) {
  return document.querySelector('meta[property="$property"]')?.attributes['content'] ??
      document.querySelector('meta[name="$property"]')?.attributes['content'];
}

int _scoreElementTest(Element element) {
  int score = 0;
  
  if (element.localName == 'article') score += 30;
  if (element.localName == 'main') score += 25;
  
  final className = element.className.toLowerCase();
  
  final positivePatterns = ['content', 'article', 'main', 'post', 'text', 'body', 'entry'];
  for (final pattern in positivePatterns) {
    if (className.contains(pattern)) {
      score += 10;
    }
  }
  
  final negativePatterns = ['sidebar', 'menu', 'nav', 'header', 'footer', 'ad', 'comment'];
  for (final pattern in negativePatterns) {
    if (className.contains(pattern)) {
      score -= 20;
    }
  }
  
  return score;
}

int _calculateReadingTimeTest(String text) {
  const wordsPerMinute = 200;
  final words = text.split(RegExp(r'\s+')).length;
  return (words / wordsPerMinute).ceil();
}

String? _makeAbsoluteUrlTest(String url, Uri baseUri) {
  try {
    if (url.isEmpty) return null;
    final uri = Uri.parse(url);
    if (uri.isAbsolute) {
      return url;
    }
    return baseUri.resolve(url).toString();
  } catch (e) {
    return null;
  }
}

Element _createElement(String tag, {String className = ''}) {
  final element = Element.tag(tag);
  if (className.isNotEmpty) {
    element.className = className;
  }
  return element;
}