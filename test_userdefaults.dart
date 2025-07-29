import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const platform = MethodChannel('com.sangdae.contentvault.dw002/userdefaults');
  
  try {
    final result = await platform.invokeMethod('getUserDefaults');
    print('UserDefaults data: $result');
  } catch (e) {
    print('Error reading UserDefaults: $e');
  }
  
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('UserDefaults Test')),
      body: const Center(
        child: Text('Check console for UserDefaults data'),
      ),
    ),
  ));
}