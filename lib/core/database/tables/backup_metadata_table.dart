import 'package:drift/drift.dart';

@DataClassName('BackupMetadata')
class BackupMetadataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get backupName => text()();
  TextColumn get backupPath => text().nullable()();
  IntColumn get contentCount => integer().withDefault(const Constant(0))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
} 