import 'package:drift/drift.dart';
import 'contents_table.dart';

@DataClassName('ArticleContent')
class ArticleContentTable extends Table {
  TextColumn get id => text()();
  TextColumn get contentId => text().references(ContentsTable, #id)();
  TextColumn get contentHtml => text()(); // Full HTML content
  TextColumn get contentText => text()(); // Plain text content
  TextColumn get images => text()(); // JSON array of image URLs
  IntColumn get readingTimeMinutes => integer()();
  TextColumn get metadata => text().nullable()(); // Additional metadata as JSON
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}