import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_state.freezed.dart';
part 'filter_state.g.dart';

@freezed
class FilterState with _$FilterState {
  const FilterState._();

  const factory FilterState({
    @Default([]) List<String> contentTypes,
    @Default([]) List<String> tags,
    DateTime? startDate,
    DateTime? endDate,
    @Default(SortBy.newest) SortBy sortBy,
    @Default(false) bool isAscending,
    @Default({}) Map<String, dynamic> customFilters,
  }) = _FilterState;

  factory FilterState.fromJson(Map<String, dynamic> json) =>
      _$FilterStateFromJson(json);

  int get activeFilterCount {
    int count = 0;
    if (contentTypes.isNotEmpty) count++;
    if (tags.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (sortBy != SortBy.newest) count++;
    if (customFilters.isNotEmpty) count += customFilters.length;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  FilterState copyWithReset() => const FilterState();

  String? validateFilters() {
    if (tags.length > 5) {
      return '최대 5개의 태그만 선택할 수 있습니다';
    }

    if (startDate != null && endDate != null) {
      if (endDate!.isBefore(startDate!)) {
        return '종료일은 시작일 이후여야 합니다';
      }

      final difference = endDate!.difference(startDate!);
      if (difference.inDays > 365) {
        return '날짜 범위는 1년을 초과할 수 없습니다';
      }
    }

    return null;
  }
}

enum SortBy {
  newest,
  oldest,
  relevance,
  title,
  source,
}

extension SortByExtension on SortBy {
  String get displayName {
    switch (this) {
      case SortBy.newest:
        return '최신순';
      case SortBy.oldest:
        return '오래된순';
      case SortBy.relevance:
        return '관련도순';
      case SortBy.title:
        return '제목순';
      case SortBy.source:
        return '출처순';
    }
  }

  String get value => name;
}