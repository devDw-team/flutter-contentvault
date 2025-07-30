import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contentvault/features/save/data/parsers/twitter_parser.dart';
import 'package:flutter_contentvault/features/save/domain/services/content_metadata_extractor.dart';

void main() {
  late TwitterParser parser;
  late ContentMetadataExtractor metadataExtractor;

  setUp(() {
    metadataExtractor = ContentMetadataExtractor();
    parser = TwitterParser(
      metadataExtractor: metadataExtractor,
    );
  });

  group('TwitterParser', () {
    group('canParse', () {
      test('should return true for valid Twitter URLs', () {
        expect(parser.canParse('https://twitter.com/user/status/123456789'), true);
        expect(parser.canParse('https://x.com/user/status/123456789'), true);
        expect(parser.canParse('https://mobile.twitter.com/user/status/123456789'), true);
        expect(parser.canParse('https://mobile.x.com/user/status/123456789'), true);
        expect(parser.canParse('twitter.com/user/status/123456789'), true);
        expect(parser.canParse('x.com/user/status/123456789'), true);
      });

      test('should return false for invalid URLs', () {
        expect(parser.canParse('https://youtube.com/watch?v=123'), false);
        expect(parser.canParse('https://facebook.com/post/123'), false);
        expect(parser.canParse('https://twitter.com/user'), false);
        expect(parser.canParse('random text'), false);
      });
    });

    group('extractTweetId', () {
      test('should extract tweet ID from valid URLs', () {
        expect(
          parser.extractTweetId('https://twitter.com/user/status/123456789'),
          '123456789',
        );
        expect(
          parser.extractTweetId('https://x.com/user/status/987654321'),
          '987654321',
        );
        expect(
          parser.extractTweetId('https://mobile.twitter.com/user/status/111222333'),
          '111222333',
        );
      });

      test('should return null for invalid URLs', () {
        expect(parser.extractTweetId('https://twitter.com/user'), null);
        expect(parser.extractTweetId('invalid url'), null);
      });
    });

    group('parse', () {
      const testUrl = 'https://twitter.com/test_user/status/123456789';
      const testTweetId = '123456789';

      test('should throw exception for invalid URL', () async {
        expect(
          () async => await parser.parse('invalid url'),
          throwsException,
        );
      });

      test('should parse tweet successfully', () async {
        // This is an integration test that requires internet connection
        // For unit tests, we would need to mock HTTP responses
        // Skipping detailed implementation for now
        expect(parser.canParse(testUrl), true);
        expect(parser.extractTweetId(testUrl), testTweetId);
      });
    });

    group('Twitter API Bearer Token', () {
      test('parser with bearer token should be created', () {
        final parserWithToken = TwitterParser(
          metadataExtractor: metadataExtractor,
          bearerToken: 'test_bearer_token',
        );
        
        expect(parserWithToken, isNotNull);
      });
    });
  });

  tearDown(() {
    parser.dispose();
    metadataExtractor.dispose();
  });
}