import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== SIMPLE SHARE TEST ===\n');
  
  // Check initial media
  print('1. Checking initial media...');
  try {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media != null && media.isNotEmpty) {
      print('Found ${media.length} shared items:');
      for (var item in media) {
        print('  - Path: ${item.path}');
        print('    Type: ${item.type}');
      }
    } else {
      print('No initial media found');
    }
  } catch (e) {
    print('Error getting initial media: $e');
  }
  
  // Set up stream listener
  print('\n2. Setting up media stream listener...');
  ReceiveSharingIntent.instance.getMediaStream().listen(
    (List<SharedMediaFile> value) {
      print('\n⚡ Received ${value.length} items from stream:');
      for (var item in value) {
        print('  - Path: ${item.path}');
        print('    Type: ${item.type}');
      }
    },
    onError: (err) {
      print('Stream error: $err');
    },
  );
  
  print('\n3. App ready. Share something to test...\n');
  
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Share Test')),
      body: const Center(
        child: Text('Share something from another app'),
      ),
    ),
  ));
}