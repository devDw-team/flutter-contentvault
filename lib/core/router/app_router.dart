import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/save/presentation/pages/save_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/ai/presentation/pages/ai_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/save',
            name: 'save',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SavePage(),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryPage(),
            ),
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      // TODO: 모달 라우트들 추가 (콘텐츠 상세, 태그 관리 등)
    ],
  );
});

final currentLocationProvider = Provider<String>((ref) {
  // TODO: 현재 라우트 위치 추적 로직 구현
  return '/home';
}); 