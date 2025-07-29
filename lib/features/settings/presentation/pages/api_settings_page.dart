import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

class ApiSettingsPage extends StatefulWidget {
  @override
  _ApiSettingsPageState createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final _youtubeApiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _youtubeApiKeyController.text = prefs.getString('youtube_api_key') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('youtube_api_key', _youtubeApiKeyController.text.trim());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API 키가 저장되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API 설정'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'YouTube Data API v3',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _youtubeApiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            hintText: 'AIzaSy...',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '이 키는 YouTube 동영상 메타데이터를 가져오는 데 사용됩니다.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          icon: Icon(Icons.open_in_new, size: 16),
                          label: Text('API 키 발급 방법'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('YouTube API 키 발급 방법'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('1. Google Cloud Console 접속'),
                                      Text('2. 새 프로젝트 생성 또는 선택'),
                                      Text('3. YouTube Data API v3 활성화'),
                                      Text('4. 사용자 인증 정보 → API 키 생성'),
                                      Text('5. 생성된 키 복사'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('닫기'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveApiKeys,
                  icon: Icon(Icons.save),
                  label: Text('저장'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _youtubeApiKeyController.dispose();
    super.dispose();
  }
}