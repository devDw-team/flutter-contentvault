import 'package:drift/drift.dart';

import 'contents_table.dart';
import 'folders_table.dart';

@DataClassName('ContentFolder')
class ContentFoldersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contentId => text().references(ContentsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get folderId => integer().references(FoldersTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {contentId, folderId}
  ];
} 