import 'package:drift/drift.dart';

@DataClassName('Folder')
class FoldersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable().references(FoldersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get icon => text().nullable()(); // 아이콘 이름
  TextColumn get color => text().nullable()(); // 폴더 색상
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
} 