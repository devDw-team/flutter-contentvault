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
import 'tables/pending_saves_table.dart';
import 'tables/youtube_metadata_table.dart';
import 'tables/article_content_table.dart';
import 'tables/threads_posts_table.dart';

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
  PendingSavesTable,
  YouTubeMetadataTable,
  ArticleContentTable,
  ThreadsPostsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Create FTS5 virtual table for full-text search
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS contents_fts USING fts5(
            content_id UNINDEXED,
            title,
            description,
            content_text,
            author,
            tags,
            platform UNINDEXED,
            content='contents_table',
            content_rowid='rowid',
            tokenize='unicode61'
          );
        ''');
        
        // Create triggers to keep FTS table in sync
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS contents_fts_insert AFTER INSERT ON contents_table BEGIN
            INSERT INTO contents_fts(content_id, title, description, content_text, author, tags, platform)
            VALUES (new.id, new.title, new.description, new.content_text, new.author, '', new.source_platform);
          END;
        ''');
        
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS contents_fts_update AFTER UPDATE ON contents_table BEGIN
            UPDATE contents_fts 
            SET title = new.title,
                description = new.description,
                content_text = new.content_text,
                author = new.author,
                platform = new.source_platform
            WHERE content_id = new.id;
          END;
        ''');
        
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS contents_fts_delete AFTER DELETE ON contents_table BEGIN
            DELETE FROM contents_fts WHERE content_id = old.id;
          END;
        ''');
        
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
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Version 2: Add pending saves table
          await m.createTable(pendingSavesTable);
        }
        if (from < 3) {
          // Version 3: Add YouTube metadata table
          await m.createTable(youTubeMetadataTable);
        }
        if (from < 4) {
          // Version 4: Add article content table
          await m.createTable(articleContentTable);
        }
        if (from < 5) {
          // Version 5: Add threads posts table
          await m.createTable(threadsPostsTable);
        }
        if (from < 6) {
          // Version 6: Add FTS5 for full-text search
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS contents_fts USING fts5(
              content_id UNINDEXED,
              title,
              description,
              content_text,
              author,
              tags,
              platform UNINDEXED,
              content='contents_table',
              content_rowid='rowid',
              tokenize='unicode61'
            );
          ''');
          
          // Create triggers
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS contents_fts_insert AFTER INSERT ON contents_table BEGIN
              INSERT INTO contents_fts(content_id, title, description, content_text, author, tags, platform)
              VALUES (new.id, new.title, new.description, new.content_text, new.author, '', new.source_platform);
            END;
          ''');
          
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS contents_fts_update AFTER UPDATE ON contents_table BEGIN
              UPDATE contents_fts 
              SET title = new.title,
                  description = new.description,
                  content_text = new.content_text,
                  author = new.author,
                  platform = new.source_platform
              WHERE content_id = new.id;
            END;
          ''');
          
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS contents_fts_delete AFTER DELETE ON contents_table BEGIN
              DELETE FROM contents_fts WHERE content_id = old.id;
            END;
          ''');
          
          // Populate FTS table with existing data
          await customStatement('''
            INSERT INTO contents_fts(content_id, title, description, content_text, author, tags, platform)
            SELECT id, title, description, content_text, author, '', source_platform
            FROM contents_table;
          ''');
        }
        if (from < 7) {
          // Version 7: Add filters column to search history
          await m.addColumn(searchHistoryTable, searchHistoryTable.filters);
        }
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