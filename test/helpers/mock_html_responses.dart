class MockHtmlResponses {
  static const String mediumArticle = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Understanding Flutter State Management - Medium</title>
    <meta name="author" content="Jane Developer">
    <meta name="description" content="A comprehensive guide to Flutter state management patterns">
    <meta property="og:title" content="Understanding Flutter State Management">
    <meta property="og:image" content="https://miro.medium.com/max/1200/1*flutter.png">
    <meta property="article:published_time" content="2024-01-20T08:00:00.000Z">
</head>
<body>
    <article>
        <header>
            <h1>Understanding Flutter State Management</h1>
            <div class="author">Jane Developer</div>
            <time>Jan 20, 2024</time>
        </header>
        <section class="content">
            <p>State management is one of the most important concepts in Flutter development. In this article, we'll explore different approaches to managing state in your Flutter applications.</p>
            
            <h2>What is State?</h2>
            <p>State refers to any data that can change over time in your application. This could be user input, data from an API, or any other dynamic information.</p>
            
            <img src="https://example.com/state-diagram.png" alt="State diagram">
            
            <h2>Popular State Management Solutions</h2>
            <p>There are several popular state management solutions in Flutter:</p>
            <ul>
                <li>Provider</li>
                <li>Riverpod</li>
                <li>Bloc</li>
                <li>GetX</li>
            </ul>
            
            <p>Each solution has its own advantages and use cases. The choice depends on your project requirements and team preferences.</p>
        </section>
    </article>
</body>
</html>
''';

  static const String newsArticle = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Tech Company Announces New Product | TechNews</title>
    <meta name="author" content="TechNews Team">
    <meta property="og:title" content="Tech Company Announces Revolutionary New Product">
    <meta property="og:description" content="Breaking: Major tech company unveils groundbreaking innovation">
    <meta property="og:image" content="https://technews.com/images/product-launch.jpg">
    <meta property="article:published_time" content="2024-01-25T14:30:00Z">
</head>
<body>
    <div class="header">Navigation Menu</div>
    <div class="sidebar">Related Articles</div>
    <main class="main-content">
        <article>
            <h1>Tech Company Announces Revolutionary New Product</h1>
            <div class="article-meta">
                <span class="author">By TechNews Team</span>
                <span class="date">January 25, 2024</span>
            </div>
            <div class="article-body">
                <p class="lead">In a surprise announcement today, a major technology company revealed their latest innovation that promises to transform the industry.</p>
                
                <p>The new product, codenamed "Project Future", represents years of research and development. Industry experts are calling it a game-changer.</p>
                
                <blockquote>"This is exactly what the market has been waiting for," said industry analyst John Smith.</blockquote>
                
                <img src="https://technews.com/images/product-photo.jpg" alt="New product">
                
                <p>The company expects to begin shipping in Q2 2024, with pre-orders starting next month.</p>
            </div>
        </article>
    </main>
    <footer>Copyright 2024 TechNews</footer>
</body>
</html>
''';

  static const String minimalHtml = '''
<!DOCTYPE html>
<html>
<head>
    <title>Simple Page</title>
</head>
<body>
    <h1>Simple Page</h1>
    <p>This is a very simple page with minimal content.</p>
</body>
</html>
''';

  static const String noContentHtml = '''
<!DOCTYPE html>
<html>
<head>
    <title>Empty Page</title>
</head>
<body>
    <script>console.log('only scripts');</script>
    <style>body { margin: 0; }</style>
</body>
</html>
''';

  static const String koreanArticle = '''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <title>플러터 개발 가이드 | 한국 기술 블로그</title>
    <meta name="author" content="김개발">
    <meta name="description" content="플러터로 크로스 플랫폼 앱을 개발하는 방법">
    <meta property="og:title" content="플러터 개발 가이드">
</head>
<body>
    <article>
        <h1>플러터 개발 가이드</h1>
        <p>플러터는 구글에서 개발한 크로스 플랫폼 프레임워크입니다. 하나의 코드베이스로 iOS, 안드로이드, 웹 애플리케이션을 개발할 수 있습니다.</p>
        
        <h2>시작하기</h2>
        <p>플러터 개발을 시작하려면 먼저 Flutter SDK를 설치해야 합니다.</p>
    </article>
</body>
</html>
''';
}