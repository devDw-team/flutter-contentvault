import 'package:drift/drift.dart';

@DataClassName('PendingSave')
class PendingSavesTable extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text().nullable()();
  TextColumn get savedText => text().nullable()();
  TextColumn get images => text().nullable()(); // JSON encoded base64 images
  TextColumn get sourcePlatform => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, processing, completed, failed
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}