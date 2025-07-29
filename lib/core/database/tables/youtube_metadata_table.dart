import 'package:drift/drift.dart';
import 'contents_table.dart';

@DataClassName('YouTubeMetadata')
class YouTubeMetadataTable extends Table {
  TextColumn get id => text()();
  TextColumn get contentId => text().references(ContentsTable, #id)();
  TextColumn get videoId => text()();
  TextColumn get channelId => text()();
  TextColumn get channelTitle => text()();
  IntColumn get duration => integer().nullable()(); // Duration in seconds
  IntColumn get viewCount => integer()();
  IntColumn get likeCount => integer()();
  BoolColumn get hasSubtitles => boolean()();
  TextColumn get tags => text().nullable()(); // JSON array of tags
  TextColumn get timestamps => text().nullable()(); // JSON array of timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}