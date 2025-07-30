class TweetModel {
  final String id;
  final String text;
  final String authorId;
  final String authorUsername;
  final String authorName;
  final String? authorProfileImageUrl;
  final DateTime createdAt;
  final List<String> mediaUrls;
  final List<MediaItem> mediaItems;
  final int? replyCount;
  final int? retweetCount;
  final int? likeCount;
  final int? viewCount;
  final String? inReplyToStatusId;
  final String? quotedTweetId;
  final TweetModel? quotedTweet;
  final Map<String, dynamic> additionalData;

  TweetModel({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorUsername,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.createdAt,
    List<String>? mediaUrls,
    List<MediaItem>? mediaItems,
    this.replyCount,
    this.retweetCount,
    this.likeCount,
    this.viewCount,
    this.inReplyToStatusId,
    this.quotedTweetId,
    this.quotedTweet,
    Map<String, dynamic>? additionalData,
  }) : mediaUrls = mediaUrls ?? [],
       mediaItems = mediaItems ?? [],
       additionalData = additionalData ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'authorId': authorId,
    'authorUsername': authorUsername,
    'authorName': authorName,
    'authorProfileImageUrl': authorProfileImageUrl,
    'createdAt': createdAt.toIso8601String(),
    'mediaUrls': mediaUrls,
    'mediaItems': mediaItems.map((e) => e.toJson()).toList(),
    'replyCount': replyCount,
    'retweetCount': retweetCount,
    'likeCount': likeCount,
    'viewCount': viewCount,
    'inReplyToStatusId': inReplyToStatusId,
    'quotedTweetId': quotedTweetId,
    'quotedTweet': quotedTweet?.toJson(),
    'additionalData': additionalData,
  };

  factory TweetModel.fromJson(Map<String, dynamic> json) => TweetModel(
    id: json['id'],
    text: json['text'],
    authorId: json['authorId'],
    authorUsername: json['authorUsername'],
    authorName: json['authorName'],
    authorProfileImageUrl: json['authorProfileImageUrl'],
    createdAt: DateTime.parse(json['createdAt']),
    mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
    mediaItems: (json['mediaItems'] as List?)
        ?.map((e) => MediaItem.fromJson(e))
        .toList() ?? [],
    replyCount: json['replyCount'],
    retweetCount: json['retweetCount'],
    likeCount: json['likeCount'],
    viewCount: json['viewCount'],
    inReplyToStatusId: json['inReplyToStatusId'],
    quotedTweetId: json['quotedTweetId'],
    quotedTweet: json['quotedTweet'] != null 
        ? TweetModel.fromJson(json['quotedTweet'])
        : null,
    additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
  );
}

class MediaItem {
  final String url;
  final MediaType type;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? durationMs;

  MediaItem({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type.name,
    'thumbnailUrl': thumbnailUrl,
    'width': width,
    'height': height,
    'durationMs': durationMs,
  };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    url: json['url'],
    type: MediaType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MediaType.photo,
    ),
    thumbnailUrl: json['thumbnailUrl'],
    width: json['width'],
    height: json['height'],
    durationMs: json['durationMs'],
  );
}

enum MediaType {
  photo,
  video,
  animatedGif,
}