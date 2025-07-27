import 'package:drift/drift.dart';

@DataClassName('UserSetting')
class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
} 