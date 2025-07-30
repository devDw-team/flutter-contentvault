import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_query_model.freezed.dart';
part 'search_query_model.g.dart';

@freezed
class SearchQueryModel with _$SearchQueryModel {
  const factory SearchQueryModel({
    required String query,
    @Default([]) List<String> platforms,
    @Default([]) List<String> contentTypes,
    @Default([]) List<String> tags,
    DateTime? startDate,
    DateTime? endDate,
    @Default('relevance') String sortBy, // relevance, date_desc, date_asc
    @Default(0) int offset,
    @Default(20) int limit,
  }) = _SearchQueryModel;

  factory SearchQueryModel.fromJson(Map<String, dynamic> json) =>
      _$SearchQueryModelFromJson(json);
}

@freezed
class SearchResultModel with _$SearchResultModel {
  const factory SearchResultModel({
    required String contentId,
    required String title,
    required String url,
    String? description,
    String? thumbnailUrl,
    required String contentType,
    required String sourcePlatform,
    String? author,
    DateTime? publishedAt,
    required DateTime createdAt,
    required double relevanceScore,
    String? highlightedTitle,
    String? highlightedDescription,
    String? highlightedContent,
    @Default([]) List<String> matchedFields,
  }) = _SearchResultModel;

  factory SearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResultModelFromJson(json);
}

@freezed
class SearchResultsModel with _$SearchResultsModel {
  const factory SearchResultsModel({
    required List<SearchResultModel> results,
    required int totalCount,
    required int offset,
    required int limit,
    required double searchDuration,
    String? suggestedQuery,
    @Default([]) List<String> relatedTags,
  }) = _SearchResultsModel;

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResultsModelFromJson(json);
}

@freezed
class SearchHistoryModel with _$SearchHistoryModel {
  const factory SearchHistoryModel({
    required String id,
    required String query,
    required DateTime searchedAt,
    required int resultCount,
    Map<String, dynamic>? filters,
  }) = _SearchHistoryModel;

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$SearchHistoryModelFromJson(json);
}