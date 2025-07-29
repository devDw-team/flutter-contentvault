class UrlValidator {
  bool isValid(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool isYouTubeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.host.contains('youtube.com') || 
           uri.host.contains('youtu.be') ||
           uri.host.contains('m.youtube.com');
  }

  bool isTwitterUrl(String url) {
    final uri = Uri.parse(url);
    return uri.host.contains('twitter.com') || 
           uri.host.contains('x.com') ||
           uri.host.contains('mobile.twitter.com');
  }

  bool isThreadsUrl(String url) {
    final uri = Uri.parse(url);
    return uri.host.contains('threads.net') || 
           uri.host.contains('www.threads.net');
  }

  bool isArticleUrl(String url) {
    // Basic heuristic for article detection
    final articleDomains = [
      'medium.com',
      'dev.to',
      'hashnode.dev',
      'substack.com',
      'wordpress.com',
      'blogspot.com',
    ];
    
    final uri = Uri.parse(url);
    return articleDomains.any((domain) => uri.host.contains(domain));
  }
}