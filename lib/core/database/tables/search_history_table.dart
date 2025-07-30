import 'package:drift/drift.dart';

@DataClassName('SearchHistory')
class SearchHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  IntColumn get resultCount => integer().withDefault(const Constant(0))();
  TextColumn get filters => text().nullable()(); // JSON encoded filters
  DateTimeColumn get searchedAt => dateTime()();
} 