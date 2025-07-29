import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() async {
  print('=== PENDING SAVES TABLE CHECK ===\n');
  
  try {
    // Get the actual app database path
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'contentvault.db');
    
    print('Database path: $dbPath');
    print('Database exists: ${File(dbPath).existsSync()}\n');
    
    if (!File(dbPath).existsSync()) {
      print('Database file not found!');
      return;
    }
    
    // Open the database
    final db = sqlite3.open(dbPath);
    
    // Check if pending_saves_table exists
    final tables = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='pending_saves_table'"
    );
    
    if (tables.isEmpty) {
      print('pending_saves_table does not exist!');
      db.dispose();
      return;
    }
    
    print('✓ pending_saves_table exists\n');
    
    // Get all records from pending_saves_table
    print('=== ALL PENDING SAVES ===');
    final allRecords = db.select('SELECT * FROM pending_saves_table ORDER BY created_at DESC');
    
    if (allRecords.isEmpty) {
      print('No records found in pending_saves_table');
    } else {
      print('Found ${allRecords.length} records:\n');
      
      for (var i = 0; i < allRecords.length; i++) {
        final record = allRecords[i];
        print('Record ${i + 1}:');
        print('  ID: ${record['id']}');
        print('  URL: ${record['url']}');
        print('  Title: ${record['title'] ?? 'NULL'}');
        print('  Status: ${record['status']}');
        print('  Platform: ${record['source_platform']}');
        print('  Created: ${record['created_at']}');
        print('  Processed: ${record['processed_at'] ?? 'NOT PROCESSED'}');
        print('  Error: ${record['error_message'] ?? 'NONE'}');
        print('  Retry Count: ${record['retry_count']}');
        print('  Text: ${record['saved_text']?.toString().substring(0, 100) ?? 'NULL'}...');
        print('  ---');
      }
    }
    
    // Check UserDefaults data
    print('\n=== CHECKING USERDEFAULTS (iOS) ===');
    // This would need to be done through iOS native code or by checking the shared container
    
    db.dispose();
    
  } catch (e) {
    print('Error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}