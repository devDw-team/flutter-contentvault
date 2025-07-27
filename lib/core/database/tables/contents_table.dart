import 'package:drift/drift.dart';

@DataClassName('Content')
class ContentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get url => text().unique()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get contentType => text()(); // 'youtube', 'twitter', 'web', 'article'
  TextColumn get sourcePlatform => text()();
  TextColumn get author => text().nullable()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  TextColumn get contentText => text().nullable()(); // 추출된 텍스트 콘텐츠
  TextColumn get metadata => text().nullable()(); // JSON 형태의 추가 메타데이터
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
} 