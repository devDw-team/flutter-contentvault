import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/save/presentation/share_extension_handler.dart';
import 'features/save/domain/services/background_save_processor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 의존성 주입 초기화
  await setupServiceLocator();
  
  // Initialize share extension handler with a small delay to ensure all dependencies are ready
  Future.delayed(const Duration(milliseconds: 500), () {
    final shareHandler = GetIt.instance<ShareExtensionHandler>();
    shareHandler.initialize();
    debugPrint('Main: ShareExtensionHandler initialized');
  });
  
  // Start background processor
  final backgroundProcessor = GetIt.instance<BackgroundSaveProcessor>();
  backgroundProcessor.startProcessing();
  
  runApp(
    const ProviderScope(
      child: ContentVaultApp(),
    ),
  );
}

class ContentVaultApp extends ConsumerWidget {
  const ContentVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'ContentVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
} 