import 'tweet_model.dart';

class TwitterThreadModel {
  final String threadId;
  final String conversationId;
  final String authorId;
  final String authorUsername;
  final String authorName;
  final String? authorProfileImageUrl;
  final List<TweetModel> tweets;
  final DateTime threadStartedAt;
  final DateTime? threadLastUpdatedAt;
  final bool isComplete;
  final Map<String, dynamic> additionalData;

  TwitterThreadModel({
    required this.threadId,
    required this.conversationId,
    required this.authorId,
    required this.authorUsername,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.tweets,
    required this.threadStartedAt,
    this.threadLastUpdatedAt,
    bool? isComplete,
    Map<String, dynamic>? additionalData,
  }) : isComplete = isComplete ?? false,
       additionalData = additionalData ?? {};

  Map<String, dynamic> toJson() => {
    'threadId': threadId,
    'conversationId': conversationId,
    'authorId': authorId,
    'authorUsername': authorUsername,
    'authorName': authorName,
    'authorProfileImageUrl': authorProfileImageUrl,
    'tweets': tweets.map((e) => e.toJson()).toList(),
    'threadStartedAt': threadStartedAt.toIso8601String(),
    'threadLastUpdatedAt': threadLastUpdatedAt?.toIso8601String(),
    'isComplete': isComplete,
    'additionalData': additionalData,
  };

  factory TwitterThreadModel.fromJson(Map<String, dynamic> json) => TwitterThreadModel(
    threadId: json['threadId'],
    conversationId: json['conversationId'],
    authorId: json['authorId'],
    authorUsername: json['authorUsername'],
    authorName: json['authorName'],
    authorProfileImageUrl: json['authorProfileImageUrl'],
    tweets: (json['tweets'] as List)
        .map((e) => TweetModel.fromJson(e))
        .toList(),
    threadStartedAt: DateTime.parse(json['threadStartedAt']),
    threadLastUpdatedAt: json['threadLastUpdatedAt'] != null 
        ? DateTime.parse(json['threadLastUpdatedAt'])
        : null,
    isComplete: json['isComplete'] ?? false,
    additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
  );
}