import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_contentvault/features/save/data/parsers/youtube_parser.dart';
import 'package:flutter_contentvault/features/save/data/api_clients/youtube_api_client.dart';
import 'package:flutter_contentvault/features/save/domain/services/content_metadata_extractor.dart';

class MockYouTubeApiClient extends Mock implements YouTubeApiClient {}
class MockContentMetadataExtractor extends Mock implements ContentMetadataExtractor {}

void main() {
  late YouTubeParser parser;
  late MockYouTubeApiClient mockApiClient;
  late MockContentMetadataExtractor mockMetadataExtractor;

  setUp(() {
    mockApiClient = MockYouTubeApiClient();
    mockMetadataExtractor = MockContentMetadataExtractor();
    parser = YouTubeParser(
      apiClient: mockApiClient,
      metadataExtractor: mockMetadataExtractor,
    );
  });

  group('YouTubeParser', () {
    group('canParse', () {
      test('should return true for valid YouTube URLs', () {
        final validUrls = [
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
          'http://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'www.youtube.com/watch?v=dQw4w9WgXcQ',
          'youtube.com/watch?v=dQw4w9WgXcQ',
          'https://youtu.be/dQw4w9WgXcQ',
          'youtu.be/dQw4w9WgXcQ',
          'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
          'https://www.youtube.com/embed/dQw4w9WgXcQ',
          'https://www.youtube.com/v/dQw4w9WgXcQ',
          'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        ];

        for (final url in validUrls) {
          expect(parser.canParse(url), isTrue, reason: 'Failed for URL: $url');
        }
      });

      test('should return false for invalid YouTube URLs', () {
        final invalidUrls = [
          'https://www.google.com',
          'https://twitter.com/status/123',
          'https://vimeo.com/123456',
          'https://www.youtube.com',
          'https://www.youtube.com/channel/UCxxxxxx',
          'not-a-url',
        ];

        for (final url in invalidUrls) {
          expect(parser.canParse(url), isFalse, reason: 'Failed for URL: $url');
        }
      });
    });

    group('extractVideoId', () {
      test('should extract video ID from various YouTube URL formats', () {
        final testCases = {
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://youtu.be/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://www.youtube.com/embed/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://www.youtube.com/v/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://m.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://www.youtube.com/shorts/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=share': 'dQw4w9WgXcQ',
          'https://www.youtube.com/watch?feature=share&v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        };

        testCases.forEach((url, expectedId) {
          expect(parser.extractVideoId(url), equals(expectedId), 
                 reason: 'Failed for URL: $url');
        });
      });

      test('should return null for invalid URLs', () {
        expect(parser.extractVideoId('https://www.google.com'), isNull);
        expect(parser.extractVideoId('not-a-url'), isNull);
      });
    });

    group('parse', () {
      final testUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final testVideoId = 'dQw4w9WgXcQ';

      test('should parse content using API data when available', () async {
        final apiData = YouTubeVideoData(
          id: testVideoId,
          title: 'Test Video',
          description: 'Test Description',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          channelTitle: 'Test Channel',
          channelId: 'UC123456',
          publishedAt: DateTime(2024, 1, 1),
          duration: Duration(minutes: 3, seconds: 52),
          viewCount: 1000000,
          likeCount: 50000,
          hasSubtitles: true,
          tags: ['music', 'test'],
        );

        when(() => mockApiClient.getVideoData(testVideoId))
            .thenAnswer((_) async => apiData);

        final content = await parser.parse(testUrl);

        expect(content.title, equals('Test Video'));
        expect(content.url, equals(testUrl));
        expect(content.description, equals('Test Description'));
        expect(content.thumbnailUrl, equals('https://example.com/thumbnail.jpg'));
        expect(content.contentType, equals('youtube'));
        expect(content.sourcePlatform, equals('youtube'));
        expect(content.author, equals('Test Channel'));
        expect(content.publishedAt, equals(DateTime(2024, 1, 1)));
        
        final metadata = jsonDecode(content.metadata!) as Map<String, dynamic>;
        expect(metadata['videoId'], equals(testVideoId));
        expect(metadata['channelTitle'], equals('Test Channel'));
        expect(metadata['channelId'], equals('UC123456'));
        expect(metadata['duration'], equals(232)); // 3:52 in seconds
        expect(metadata['viewCount'], equals(1000000));
        expect(metadata['likeCount'], equals(50000));
        expect(metadata['hasSubtitles'], isTrue);
        expect(metadata['tags'], equals(['music', 'test']));
      });

      test('should fallback to web scraping when API fails', () async {
        when(() => mockApiClient.getVideoData(testVideoId))
            .thenThrow(Exception('API quota exceeded'));

        when(() => mockMetadataExtractor.extractMetadata(
              url: testUrl,
              platform: 'youtube',
            )).thenAnswer((_) async => ContentMetadata(
              title: 'Scraped Video Title',
              description: 'Scraped Description',
              thumbnailUrl: 'https://example.com/scraped-thumbnail.jpg',
              author: 'Scraped Channel',
              additionalData: {'videoId': testVideoId},
            ));

        final content = await parser.parse(testUrl);

        expect(content.title, equals('Scraped Video Title'));
        expect(content.url, equals(testUrl));
        expect(content.description, equals('Scraped Description'));
        expect(content.thumbnailUrl, equals('https://example.com/scraped-thumbnail.jpg'));
        expect(content.author, equals('Scraped Channel'));
      });

      test('should throw exception for invalid URL', () async {
        expect(
          () => parser.parse('https://www.google.com'),
          throwsException,
        );
      });
    });

    group('timestamp parsing', () {
      test('should parse timestamps from description', () async {
        final apiData = YouTubeVideoData(
          id: 'test123',
          title: 'Test Video',
          description: '''
0:00 Introduction
2:30 Main Content
5:45 - Conclusion
10:00 End Credits

Some other text here
[15:30] Bonus Content
[20:00] - Final Thoughts
          ''',
          thumbnailUrl: '',
          channelTitle: 'Test Channel',
          channelId: 'UC123',
          viewCount: 0,
          likeCount: 0,
          hasSubtitles: false,
          tags: [],
        );

        when(() => mockApiClient.getVideoData('test123'))
            .thenAnswer((_) async => apiData);

        final content = await parser.parse('https://youtube.com/watch?v=test123');
        final metadata = jsonDecode(content.metadata!) as Map<String, dynamic>;
        final timestamps = metadata['timestamps'] as List<dynamic>;

        expect(timestamps.length, greaterThan(0));
        expect(timestamps[0]['time'], equals('0:00'));
        expect(timestamps[0]['title'], equals('Introduction'));
        expect(timestamps[1]['time'], equals('2:30'));
        expect(timestamps[1]['title'], equals('Main Content'));
      });
    });
  });
}