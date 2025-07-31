import 'package:freezed_annotation/freezed_annotation.dart';
import 'filter_state.dart';

part 'filter_options.freezed.dart';
part 'filter_options.g.dart';

@freezed
class FilterOptions with _$FilterOptions {
  const factory FilterOptions({
    @Default(['youtube', 'twitter', 'article', 'bookmark']) List<String> availableContentTypes,
    @Default([]) List<String> availableTags,
    @Default([]) List<FilterPreset> savedPresets,
    @Default({}) Map<String, List<String>> mutuallyExclusiveGroups,
    @Default({}) Map<String, List<String>> dependentFilters,
  }) = _FilterOptions;

  factory FilterOptions.fromJson(Map<String, dynamic> json) =>
      _$FilterOptionsFromJson(json);
}

@freezed
class FilterPreset with _$FilterPreset {
  const factory FilterPreset({
    required String id,
    required String name,
    required FilterState filterState,
    @Default(false) bool isDefault,
    DateTime? createdAt,
  }) = _FilterPreset;

  factory FilterPreset.fromJson(Map<String, dynamic> json) =>
      _$FilterPresetFromJson(json);
}

class ContentTypeFilter {
  static const String youtube = 'youtube';
  static const String twitter = 'twitter';
  static const String article = 'article';
  static const String bookmark = 'bookmark';

  static String getDisplayName(String type) {
    switch (type) {
      case youtube:
        return 'YouTube';
      case twitter:
        return 'X (Twitter)';
      case article:
        return '아티클';
      case bookmark:
        return '북마크';
      default:
        return type;
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case youtube:
        return '🎥';
      case twitter:
        return '🐦';
      case article:
        return '📄';
      case bookmark:
        return '⭐';
      default:
        return '📁';
    }
  }
}