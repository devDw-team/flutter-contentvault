import 'package:json_annotation/json_annotation.dart';

part 'article_model.g.dart';

@JsonSerializable()
class ArticleModel {
  final String id;
  final String url;
  final String title;
  final String? author;
  final DateTime? publishedAt;
  final String? description;
  final String? thumbnailUrl;
  final String contentHtml;
  final String contentText;
  final List<String> images;
  final int readingTimeMinutes;
  final Map<String, dynamic> metadata;

  ArticleModel({
    required this.id,
    required this.url,
    required this.title,
    this.author,
    this.publishedAt,
    this.description,
    this.thumbnailUrl,
    required this.contentHtml,
    required this.contentText,
    required this.images,
    required this.readingTimeMinutes,
    required this.metadata,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => _$ArticleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleModelToJson(this);
}