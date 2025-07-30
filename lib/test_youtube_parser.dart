import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'features/save/data/parsers/youtube_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // API 키 확인 (설정 페이지에서 저장된 키 사용)
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('youtube_api_key');
  
  if (apiKey == null || apiKey.isEmpty) {
    // 테스트용 임시 키 설정 (실제 API 키로 교체 필요)
    await prefs.setString('youtube_api_key', 'AIzaSyCACMfpLMII6O0BxuRLXofmEfUi6UHSKcg');
    print('⚠️ YouTube API 키가 설정되지 않았습니다. 설정 페이지에서 API 키를 입력하세요.');
  }
  
  // 서비스 초기화
  await setupServiceLocator();
  
  runApp(YouTubeParserTestApp());
}

class YouTubeParserTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Parser Test',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: YouTubeParserTestScreen(),
    );
  }
}

class YouTubeParserTestScreen extends StatefulWidget {
  @override
  _YouTubeParserTestScreenState createState() => _YouTubeParserTestScreenState();
}

class _YouTubeParserTestScreenState extends State<YouTubeParserTestScreen> {
  final _urlController = TextEditingController();
  final _youtubeParser = getIt<YouTubeParser>();
  bool _isLoading = false;
  String? _result;

  // 테스트용 YouTube URL 목록
  final List<String> testUrls = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtu.be/jNQXAC9IVRw',
    'https://www.youtube.com/shorts/rUxyKA_-grg',
    'https://m.youtube.com/watch?v=M7lc1UVf-VE',
  ];

  Future<void> _testParser() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final url = _urlController.text.trim();
      
      // URL 유효성 검사
      if (!_youtubeParser.canParse(url)) {
        setState(() {
          _result = '❌ 유효하지 않은 YouTube URL입니다.';
        });
        return;
      }

      // 비디오 ID 추출
      final videoId = _youtubeParser.extractVideoId(url);
      if (videoId == null) {
        setState(() {
          _result = '❌ 비디오 ID를 추출할 수 없습니다.';
        });
        return;
      }

      // 콘텐츠 파싱
      final stopwatch = Stopwatch()..start();
      final content = await _youtubeParser.parse(url);
      stopwatch.stop();
      
      setState(() {
        _result = '''
✅ 파싱 성공! (소요시간: ${stopwatch.elapsedMilliseconds}ms)

📹 제목: ${content.title}
👤 채널: ${content.author ?? '알 수 없음'}
📝 설명: ${content.description ?? '없음'}
🖼️ 썸네일: ${content.thumbnailUrl ?? '없음'}
📅 게시일: ${content.publishedAt?.toString() ?? '알 수 없음'}
🆔 콘텐츠 ID: ${content.id}
🔗 URL: ${content.url}

🔍 메타데이터:
${_formatMetadata(content.metadata)}
        ''';
      });
    } catch (e) {
      setState(() {
        _result = '''
❌ 오류 발생: $e

💡 확인사항:
1. YouTube API 키가 설정되었는지 확인
2. 인터넷 연결 상태 확인
3. 동영상이 삭제되거나 비공개가 아닌지 확인
        ''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return '없음';
    
    final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
    
    final buffer = StringBuffer();
    metadata.forEach((key, value) {
      if (key == 'timestamps' && value is List) {
        buffer.writeln('  $key:');
        for (var timestamp in value) {
          if (timestamp is Map) {
            buffer.writeln('    ${timestamp['time']} - ${timestamp['title']}');
          }
        }
      } else if (value is List) {
        buffer.writeln('  $key: ${value.length}개 항목');
        if (value.isNotEmpty && value.length <= 5) {
          buffer.writeln('    ${value.join(', ')}');
        }
      } else if (value is Map) {
        buffer.writeln('  $key: ${value.length}개 필드');
      } else {
        buffer.writeln('  $key: $value');
      }
    });
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Parser 테스트'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YouTube URL 입력',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://www.youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '샘플 URL:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: testUrls.map((url) => 
                        ActionChip(
                          label: Text(
                            Uri.parse(url).host + '...',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            _urlController.text = url;
                          },
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testParser,
              icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.play_arrow),
              label: Text(_isLoading ? '파싱 중...' : '테스트 실행'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            if (_result != null)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: SelectableText(
                      _result!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}