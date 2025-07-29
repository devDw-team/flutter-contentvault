import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'core/di/service_locator.dart';
import 'features/save/presentation/share_extension_handler.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await setupServiceLocator();
  
  print('=== MANUAL USERDEFAULTS CHECK ===\n');
  
  // Method channel to read UserDefaults directly
  const platform = MethodChannel('contentvault/userdefaults');
  
  // Create native method channel handler
  platform.setMethodCallHandler((call) async {
    print('Received method call: ${call.method}');
    return null;
  });
  
  // Get share handler
  final shareHandler = GetIt.instance<ShareExtensionHandler>();
  shareHandler.initialize();
  
  // Check database after a delay
  await Future.delayed(const Duration(seconds: 2));
  
  final database = GetIt.instance<AppDatabase>();
  final pendingSaves = await database.select(database.pendingSavesTable).get();
  
  print('\nPending saves in database: ${pendingSaves.length}');
  for (var save in pendingSaves) {
    print('- URL: ${save.url}');
    print('  Status: ${save.status}');
    print('  Created: ${save.createdAt}');
  }
  
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Manual UserDefaults Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Force check for shared data
            print('\nForce checking for shared data...');
            shareHandler.initialize();
          },
          child: const Text('Check UserDefaults'),
        ),
      ),
    ),
  ));
}