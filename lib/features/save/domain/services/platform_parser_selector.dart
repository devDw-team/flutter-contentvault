import 'url_validator.dart';
import '../../data/parsers/youtube_parser.dart';
import '../../data/parsers/twitter_parser.dart';
import '../../data/parsers/web_parser.dart';
import '../../data/parsers/threads_parser.dart';
import '../../../../core/database/app_database.dart';

class PlatformParserSelector {
  final _urlValidator = UrlValidator();
  final YouTubeParser? youtubeParser;
  final TwitterParser? twitterParser;
  final WebParser? webParser;
  final ThreadsParser? threadsParser;

  PlatformParserSelector({
    this.youtubeParser,
    this.twitterParser,
    this.webParser,
    this.threadsParser,
  });

  String selectPlatform(String url) {
    if (_urlValidator.isYouTubeUrl(url)) {
      return 'youtube';
    } else if (_urlValidator.isTwitterUrl(url)) {
      return 'twitter';
    } else if (_urlValidator.isThreadsUrl(url)) {
      return 'threads';
    } else if (_urlValidator.isArticleUrl(url)) {
      return 'article';
    } else {
      return 'web';
    }
  }

  Future<Content?> parseContent(String url) async {
    final platform = selectPlatform(url);
    
    switch (platform) {
      case 'youtube':
        if (youtubeParser != null && youtubeParser!.canParse(url)) {
          return await youtubeParser!.parse(url);
        }
        break;
      case 'twitter':
        if (twitterParser != null && twitterParser!.canParse(url)) {
          return await twitterParser!.parse(url);
        }
        break;
      case 'threads':
        if (threadsParser != null && threadsParser!.canParse(url)) {
          return await threadsParser!.parse(url);
        }
        break;
      case 'article':
      case 'web':
        if (webParser != null && webParser!.canParse(url)) {
          return await webParser!.parseToContent(url);
        }
        break;
    }
    
    return null;
  }

  Map<String, dynamic> getPlatformMetadata(String platform) {
    switch (platform) {
      case 'youtube':
        return {
          'icon': 'youtube',
          'color': '#FF0000',
          'displayName': 'YouTube',
        };
      case 'twitter':
        return {
          'icon': 'twitter',
          'color': '#1DA1F2',
          'displayName': 'X (Twitter)',
        };
      case 'threads':
        return {
          'icon': 'threads',
          'color': '#000000',
          'displayName': 'Threads',
        };
      case 'article':
        return {
          'icon': 'article',
          'color': '#4CAF50',
          'displayName': 'Article',
        };
      default:
        return {
          'icon': 'web',
          'color': '#2196F3',
          'displayName': 'Web',
        };
    }
  }
}