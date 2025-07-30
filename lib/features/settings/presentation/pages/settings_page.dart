import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: const [
          _GeneralSection(),
          _AppearanceSection(),
          _DataSection(),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '일반',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('알림'),
          subtitle: const Text('새로운 콘텐츠 추천 및 업데이트 알림'),
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: 알림 설정 토글
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('언어'),
          subtitle: const Text('한국어'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 언어 선택 다이얼로그
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('자동 다운로드'),
          subtitle: const Text('WiFi 연결 시 콘텐츠 자동 다운로드'),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              // TODO: 자동 다운로드 설정 토글
            },
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '외관',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('테마'),
          subtitle: const Text('시스템 설정 따름'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showThemeDialog(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: const Text('글꼴 크기'),
          subtitle: const Text('보통'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 글꼴 크기 선택 다이얼로그
          },
        ),
        ListTile(
          leading: const Icon(Icons.view_module),
          title: const Text('기본 보기 방식'),
          subtitle: const Text('리스트'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 기본 보기 방식 선택 다이얼로그
          },
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('라이트'),
              value: 'light',
              groupValue: 'system',
              onChanged: (value) {
                // TODO: 테마 변경
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('다크'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (value) {
                // TODO: 테마 변경
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('시스템 설정 따름'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) {
                // TODO: 테마 변경
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '데이터',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('백업 및 복원'),
          subtitle: const Text('데이터를 안전하게 백업하고 복원'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 백업 관리 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_sync),
          title: const Text('자동 백업'),
          subtitle: const Text('매일 자동으로 클라우드에 백업'),
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // TODO: 자동 백업 설정 토글
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('저장 공간'),
          subtitle: const Text('사용 중: 0 MB / 총 용량: 무제한'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 저장 공간 관리 페이지로 이동
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
          title: Text(
            '모든 데이터 삭제',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: const Text('앱의 모든 데이터를 삭제합니다 (복구 불가)'),
          onTap: () {
            _showDeleteAllDataDialog(context);
          },
        ),
      ],
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '정말로 모든 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 모든 데이터 삭제
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('앱 정보'),
          subtitle: const Text('버전 1.0.0'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 앱 정보 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('디버그 정보'),
          subtitle: const Text('Share Extension 상태 확인'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push('/debug');
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('개인정보 처리방침'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 개인정보 처리방침 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('이용약관'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 이용약관 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('도움말'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 도움말 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('피드백 보내기'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 피드백 보내기
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'ContentVault v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
} 