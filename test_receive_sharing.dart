import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TESTING RECEIVE SHARING INTENT ===\n');
  
  // Check SharedPreferences/UserDefaults directly
  final prefs = await SharedPreferences.getInstance();
  print('1. Checking SharedPreferences keys:');
  final keys = prefs.getKeys();
  for (final key in keys) {
    print('   Key: $key, Value: ${prefs.get(key)}');
  }
  
  // Check initial media
  print('\n2. Checking initial media:');
  try {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media != null && media.isNotEmpty) {
      print('   Found ${media.length} shared items:');
      for (var i = 0; i < media.length; i++) {
        final item = media[i];
        print('   Item $i:');
        print('     Path: ${item.path}');
        print('     Type: ${item.type}');
        print('     Thumbnail: ${item.thumbnail}');
        print('     Duration: ${item.duration}');
      }
    } else {
      print('   No initial media found');
    }
  } catch (e) {
    print('   Error: $e');
  }
  
  // Reset and check again
  print('\n3. Resetting and checking again:');
  ReceiveSharingIntent.instance.reset();
  await Future.delayed(Duration(milliseconds: 100));
  
  try {
    final media2 = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media2 != null && media2.isNotEmpty) {
      print('   After reset - Found ${media2.length} items');
    } else {
      print('   After reset - No media found');
    }
  } catch (e) {
    print('   Error after reset: $e');
  }
  
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Receive Sharing Test')),
      body: const Center(
        child: Text('Check console for debug output'),
      ),
    ),
  ));
}