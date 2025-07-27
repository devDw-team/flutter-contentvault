import 'package:drift/drift.dart';

import 'contents_table.dart';
import 'tags_table.dart';

@DataClassName('ContentTag')
class ContentTagsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contentId => text().references(ContentsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(TagsTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {contentId, tagId}
  ];
} 