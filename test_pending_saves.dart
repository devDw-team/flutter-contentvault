import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'lib/core/database/app_database.dart';

void main() async {
  // Database file path
  final dbPath = p.join(Directory.current.path, 'test_contentvault.db');
  print('Database path: $dbPath');
  
  // Create database connection
  final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
  
  try {
    // Get all pending saves
    final pendingSaves = await db.select(db.pendingSavesTable).get();
    
    print('\n=== PENDING SAVES TABLE DATA ===');
    print('Total records: ${pendingSaves.length}');
    print('');
    
    if (pendingSaves.isEmpty) {
      print('No pending saves found in the database.');
    } else {
      for (var i = 0; i < pendingSaves.length; i++) {
        final save = pendingSaves[i];
        print('Record ${i + 1}:');
        print('  ID: ${save.id}');
        print('  URL: ${save.url}');
        print('  Title: ${save.title ?? 'N/A'}');
        print('  Status: ${save.status}');
        print('  Platform: ${save.sourcePlatform}');
        print('  Created: ${save.createdAt}');
        print('  Processed: ${save.processedAt ?? 'Not processed'}');
        print('  Error: ${save.errorMessage ?? 'None'}');
        print('  Retry Count: ${save.retryCount}');
        print('---');
      }
    }
    
    // Check for pending status only
    final onlyPending = await (db.select(db.pendingSavesTable)
      ..where((tbl) => tbl.status.equals('pending')))
      .get();
    
    print('\nPending status only: ${onlyPending.length} records');
    
  } catch (e) {
    print('Error reading pending saves: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    await db.close();
  }
}

// Extension to create test database
extension TestDatabase on AppDatabase {
  static AppDatabase forTesting(QueryExecutor executor) {
    return AppDatabase.forTesting(executor);
  }
}