import 'package:drift/drift.dart';

@DataClassName('ThreadsPost')
class ThreadsPostsTable extends Table {
  TextColumn get id => text()();
  TextColumn get contentId => text()(); // Will add foreign key constraint later
  TextColumn get postId => text()(); // Threads post ID
  TextColumn get conversationId => text()();
  TextColumn get authorId => text()();
  TextColumn get authorUsername => text()();
  TextColumn get authorName => text()();
  TextColumn get authorProfileImageUrl => text().nullable()();
  TextColumn get postText => text()(); // Changed from 'text' to avoid reserved word
  TextColumn get mediaAssets => text().nullable()(); // JSON encoded MediaAsset array
  IntColumn get replyCount => integer().nullable()();
  IntColumn get likeCount => integer().nullable()();
  IntColumn get repostCount => integer().nullable()();
  TextColumn get inReplyToId => text().nullable()();
  TextColumn get quotedPostId => text().nullable()();
  TextColumn get mentions => text().nullable()(); // JSON encoded array
  TextColumn get hashtags => text().nullable()(); // JSON encoded array
  IntColumn get postOrder => integer()(); // Order in conversation
  DateTimeColumn get postedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}