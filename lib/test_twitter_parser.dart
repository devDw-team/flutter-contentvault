import 'dart:convert';
import 'package:flutter_contentvault/features/save/data/parsers/twitter_parser.dart';
import 'package:flutter_contentvault/features/save/domain/services/content_metadata_extractor.dart';

/// Manual test script for Twitter parser
/// 
/// Usage:
/// ```bash
/// flutter run lib/test_twitter_parser.dart
/// ```
void main() async {
  print('Twitter Parser Test\n');
  print('==================\n');

  // Initialize parser
  final metadataExtractor = ContentMetadataExtractor();
  final parser = TwitterParser(
    metadataExtractor: metadataExtractor,
    // Optional: Add your Twitter API Bearer Token here for API testing
    // bearerToken: 'YOUR_BEARER_TOKEN_HERE',
  );

  // Test URLs
  final testUrls = [
    'https://twitter.com/elonmusk/status/1234567890123456789',
    'https://x.com/Google/status/9876543210987654321',
    'https://mobile.twitter.com/flutter/status/1111111111111111111',
    'https://x.com/thread_example/status/2222222222222222222',
  ];

  print('Testing URL validation:\n');
  for (final url in testUrls) {
    final canParse = parser.canParse(url);
    final tweetId = parser.extractTweetId(url);
    print('URL: $url');
    print('Can Parse: $canParse');
    print('Tweet ID: $tweetId');
    print('---');
  }

  print('\nTesting actual parsing (requires internet connection):\n');
  
  // Test with a real tweet URL
  const realTweetUrl = 'https://twitter.com/FlutterDev/status/1234567890123456789';
  
  try {
    print('Parsing: $realTweetUrl');
    final content = await parser.parse(realTweetUrl);
    
    print('\nParsed Content:');
    print('Title: ${content.title}');
    print('Author: ${content.author}');
    print('Description: ${content.description}');
    print('Thumbnail: ${content.thumbnailUrl}');
    print('Content Type: ${content.contentType}');
    print('Platform: ${content.sourcePlatform}');
    print('Published: ${content.publishedAt}');
    print('\nContent Text (first 200 chars):');
    print(content.contentText?.substring(0, 
      content.contentText!.length > 200 ? 200 : content.contentText!.length));
    
    if (content.metadata != null) {
      print('\nMetadata:');
      final metadata = jsonDecode(content.metadata!);
      print(const JsonEncoder.withIndent('  ').convert(metadata));
    }
  } catch (e) {
    print('Error parsing tweet: $e');
  }

  // Cleanup
  parser.dispose();
  metadataExtractor.dispose();
}

/// Test specific features
void testSpecificFeatures() async {
  print('\n\nTesting Specific Features\n');
  print('========================\n');

  final metadataExtractor = ContentMetadataExtractor();
  
  // Test with Bearer Token (Twitter API)
  print('1. Testing with Twitter API (requires valid Bearer Token):\n');
  final apiParser = TwitterParser(
    metadataExtractor: metadataExtractor,
    bearerToken: 'YOUR_BEARER_TOKEN_HERE', // Replace with actual token
  );
  
  // Test thread parsing
  print('2. Testing thread parsing capability:\n');
  const threadUrl = 'https://twitter.com/user/status/1234567890123456789';
  
  try {
    final content = await apiParser.parse(threadUrl);
    final metadata = jsonDecode(content.metadata!);
    
    if (metadata['tweetCount'] != null && metadata['tweetCount'] > 1) {
      print('Thread detected with ${metadata['tweetCount']} tweets');
      print('Thread ID: ${metadata['threadId']}');
    } else {
      print('Single tweet (not a thread)');
    }
  } catch (e) {
    print('Error: $e');
  }

  // Test media extraction
  print('\n3. Testing media extraction:\n');
  const mediaUrl = 'https://twitter.com/user/status/1234567890123456789';
  
  try {
    final content = await apiParser.parse(mediaUrl);
    final metadata = jsonDecode(content.metadata!);
    final mediaUrls = metadata['mediaUrls'] as List?;
    
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      print('Found ${mediaUrls.length} media items:');
      for (final url in mediaUrls) {
        print('  - $url');
      }
    } else {
      print('No media found in tweet');
    }
  } catch (e) {
    print('Error: $e');
  }

  // Cleanup
  apiParser.dispose();
  metadataExtractor.dispose();
}