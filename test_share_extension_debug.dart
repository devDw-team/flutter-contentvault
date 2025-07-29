import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'core/di/service_locator.dart';
import 'features/save/presentation/share_extension_handler.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await setupServiceLocator();
  
  print('=== SHARE EXTENSION DEBUG TEST ===\n');
  
  // Get instances
  final database = GetIt.instance<AppDatabase>();
  final shareHandler = GetIt.instance<ShareExtensionHandler>();
  
  try {
    // Initialize share handler
    print('1. Initializing share handler...');
    shareHandler.initialize();
    print('   ✓ Share handler initialized\n');
    
    // Check for initial shared data
    print('2. Checking for initial shared data...');
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia != null && initialMedia.isNotEmpty) {
      print('   ✓ Found ${initialMedia.length} shared items:');
      for (var i = 0; i < initialMedia.length; i++) {
        final item = initialMedia[i];
        print('     Item $i: path="${item.path}", type=${item.type}');
      }
    } else {
      print('   ✗ No initial shared data found');
    }
    print('');
    
    // Check pending saves in database
    print('3. Checking pending saves in database...');
    final pendingSaves = await database.select(database.pendingSavesTable).get();
    print('   Found ${pendingSaves.length} pending saves:');
    
    for (var save in pendingSaves) {
      print('   - ID: ${save.id}');
      print('     URL: ${save.url}');
      print('     Status: ${save.status}');
      print('     Created: ${save.createdAt}');
    }
    
    if (pendingSaves.isEmpty) {
      print('   ✗ No pending saves found');
    }
    print('');
    
    // Listen for incoming shares
    print('4. Setting up listener for incoming shares...');
    ReceiveSharingIntent.instance.getMediaStream().listen((data) {
      print('   ⚡ Received shared data: ${data.length} items');
      for (var item in data) {
        print('     - path: ${item.path}');
      }
    });
    print('   ✓ Listener active\n');
    
    // Check UserDefaults (iOS specific)
    print('5. App is ready to receive shares\n');
    
  } catch (e) {
    print('ERROR: $e');
    print('Stack trace: ${StackTrace.current}');
  }
  
  // Keep the app running to receive shares
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Share Extension Debug')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Share Extension Debug Mode'),
                SizedBox(height: 20),
                Text('Share a URL from another app to test'),
                SizedBox(height: 10),
                Text('Check console for debug output'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}