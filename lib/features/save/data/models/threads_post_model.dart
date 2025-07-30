import 'package:freezed_annotation/freezed_annotation.dart';

part 'threads_post_model.freezed.dart';
part 'threads_post_model.g.dart';

@freezed
class ThreadsPostModel with _$ThreadsPostModel {
  const factory ThreadsPostModel({
    required String id,
    required String text,
    required String authorId,
    required String authorUsername,
    required String authorName,
    String? authorProfileImageUrl,
    required DateTime createdAt,
    List<String>? mediaUrls,
    List<MediaAsset>? mediaAssets,
    int? replyCount,
    int? likeCount,
    int? repostCount,
    String? inReplyToId,
    String? quotedPostId,
    List<String>? mentions,
    List<String>? hashtags,
    Map<String, dynamic>? additionalData,
  }) = _ThreadsPostModel;

  factory ThreadsPostModel.fromJson(Map<String, dynamic> json) =>
      _$ThreadsPostModelFromJson(json);
}

@freezed
class MediaAsset with _$MediaAsset {
  const factory MediaAsset({
    required String url,
    required String type, // image, video, link_card
    String? thumbnailUrl,
    int? width,
    int? height,
    int? duration, // for videos
    String? altText,
    Map<String, dynamic>? metadata,
  }) = _MediaAsset;

  factory MediaAsset.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetFromJson(json);
}

@freezed
class ThreadsConversationModel with _$ThreadsConversationModel {
  const factory ThreadsConversationModel({
    required String conversationId,
    required String authorId,
    required String authorUsername,
    required String authorName,
    String? authorProfileImageUrl,
    required List<ThreadsPostModel> posts,
    required DateTime conversationStartedAt,
    DateTime? conversationLastUpdatedAt,
    required bool isComplete,
    Map<String, dynamic>? additionalData,
  }) = _ThreadsConversationModel;

  factory ThreadsConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ThreadsConversationModelFromJson(json);
}