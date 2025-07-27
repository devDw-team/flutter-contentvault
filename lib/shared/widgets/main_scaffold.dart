import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppTheme.shortDuration,
        child: child,
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _BottomNavigationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(currentLocation);
    
    return TweenAnimationBuilder<double>(
      duration: AppTheme.mediumDuration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 80 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                HapticFeedback.lightImpact();
                _onDestinationSelected(context, index);
              },
              destinations: [
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 0
                        ? const Icon(Icons.home, key: ValueKey('home_selected'))
                        : const Icon(Icons.home_outlined, key: ValueKey('home_unselected')),
                  ),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 1
                        ? const Icon(Icons.add_circle, key: ValueKey('add_selected'))
                        : const Icon(Icons.add_circle_outline, key: ValueKey('add_unselected')),
                  ),
                  label: '저장',
                ),
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 2
                        ? const Icon(Icons.search, key: ValueKey('search_selected'))
                        : const Icon(Icons.search_outlined, key: ValueKey('search_unselected')),
                  ),
                  label: '검색',
                ),
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 3
                        ? const Icon(Icons.library_books, key: ValueKey('library_selected'))
                        : const Icon(Icons.library_books_outlined, key: ValueKey('library_unselected')),
                  ),
                  label: '라이브러리',
                ),
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 4
                        ? const Icon(Icons.psychology, key: ValueKey('ai_selected'))
                        : const Icon(Icons.psychology_outlined, key: ValueKey('ai_unselected')),
                  ),
                  label: 'AI',
                ),
                NavigationDestination(
                  icon: AnimatedSwitcher(
                    duration: AppTheme.shortDuration,
                    child: selectedIndex == 5
                        ? const Icon(Icons.settings, key: ValueKey('settings_selected'))
                        : const Icon(Icons.settings_outlined, key: ValueKey('settings_unselected')),
                  ),
                  label: '설정',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case '/home':
        return 0;
      case '/save':
        return 1;
      case '/search':
        return 2;
      case '/library':
        return 3;
      case '/ai':
        return 4;
      case '/settings':
        return 5;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    // 현재 인덱스와 동일한 경우 아무 작업도 하지 않음
    final currentIndex = _getSelectedIndex(GoRouterState.of(context).uri.path);
    if (currentIndex == index) return;
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/save');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/library');
        break;
      case 4:
        context.go('/ai');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }
}