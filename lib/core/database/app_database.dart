import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/contents_table.dart';
import 'tables/tags_table.dart';
import 'tables/content_tags_table.dart';
import 'tables/folders_table.dart';
import 'tables/content_folders_table.dart';
import 'tables/ai_analysis_table.dart';
import 'tables/search_history_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/backup_metadata_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ContentsTable,
  TagsTable,
  ContentTagsTable,
  FoldersTable,
  ContentFoldersTable,
  AiAnalysisTable,
  SearchHistoryTable,
  UserSettingsTable,
  BackupMetadataTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // 기본 폴더 생성
        await batch((batch) {
          batch.insertAll(foldersTable, [
          FoldersTableCompanion.insert(
            name: '일반',
            icon: const Value('folder'),
            color: const Value('#2196F3'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          FoldersTableCompanion.insert(
            name: '즐겨찾기',
            icon: const Value('star'),
            color: const Value('#FF9800'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          FoldersTableCompanion.insert(
            name: '나중에 읽기',
            icon: const Value('schedule'),
            color: const Value('#4CAF50'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ]);
        });

        // 기본 태그 생성
        await batch((batch) {
          batch.insertAll(tagsTable, [
          TagsTableCompanion.insert(
            name: '기술',
            color: const Value('#2196F3'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TagsTableCompanion.insert(
            name: '뉴스',
            color: const Value('#F44336'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TagsTableCompanion.insert(
            name: '교육',
            color: const Value('#4CAF50'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TagsTableCompanion.insert(
            name: '엔터테인먼트',
            color: const Value('#9C27B0'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ]);
        });

        // 기본 설정값 생성
        await batch((batch) {
          batch.insertAll(userSettingsTable, [
          UserSettingsTableCompanion.insert(
            key: 'db_version',
            value: '1.0.0',
            updatedAt: DateTime.now(),
          ),
          UserSettingsTableCompanion.insert(
            key: 'app_theme',
            value: 'system',
            updatedAt: DateTime.now(),
          ),
          UserSettingsTableCompanion.insert(
            key: 'auto_backup',
            value: 'true',
            updatedAt: DateTime.now(),
          ),
          ]);
        });
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'contentvault.db'));
    
    return NativeDatabase.createInBackground(file);
  });
} 