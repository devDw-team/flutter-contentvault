import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contentvault/features/search/models/filter_state.dart';
import 'package:flutter_contentvault/features/search/models/filter_options.dart';
import 'package:flutter_contentvault/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';

part 'filter_provider.g.dart';

@riverpod
class FilterStateNotifier extends _$FilterStateNotifier {
  static const String _filterStateKey = 'search_filter_state';
  static const String _filterPresetsKey = 'search_filter_presets';
  static const String _availableTagsKey = 'available_tags';

  late final SharedPreferences _prefs;

  @override
  FutureOr<FilterState> build() async {
    _prefs = getIt<SharedPreferences>();
    return _loadFilterState();
  }

  FilterState _loadFilterState() {
    final jsonString = _prefs.getString(_filterStateKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return FilterState.fromJson(json);
      } catch (e) {
        // If loading fails, return default state
        return const FilterState();
      }
    }
    return const FilterState();
  }

  Future<void> updateFilters(FilterState newState) async {
    state = AsyncData(newState);
    await _saveFilterState(newState);
  }

  Future<void> _saveFilterState(FilterState filterState) async {
    final json = filterState.toJson();
    await _prefs.setString(_filterStateKey, jsonEncode(json));
  }

  Future<void> resetFilters() async {
    const defaultState = FilterState();
    state = const AsyncData(defaultState);
    await _prefs.remove(_filterStateKey);
  }
}

@riverpod
class FilterOptionsNotifier extends _$FilterOptionsNotifier {
  static const String _filterPresetsKey = 'search_filter_presets';
  static const String _availableTagsKey = 'available_tags';

  late final SharedPreferences _prefs;
  final _uuid = const Uuid();

  @override
  FutureOr<FilterOptions> build() async {
    _prefs = getIt<SharedPreferences>();
    return _loadFilterOptions();
  }

  FilterOptions _loadFilterOptions() {
    final presets = _loadPresets();
    final tags = _loadAvailableTags();

    return FilterOptions(
      availableTags: tags,
      savedPresets: presets,
      mutuallyExclusiveGroups: {
        'dateRange': ['today', 'thisWeek', 'thisMonth', 'custom'],
      },
      dependentFilters: {
        'customDateRange': ['startDate', 'endDate'],
      },
    );
  }

  List<FilterPreset> _loadPresets() {
    final jsonString = _prefs.getString(_filterPresetsKey);
    if (jsonString != null) {
      try {
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((json) => FilterPreset.fromJson(json))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  List<String> _loadAvailableTags() {
    final tags = _prefs.getStringList(_availableTagsKey);
    return tags ?? [];
  }

  Future<void> savePreset(String name, FilterState filterState) async {
    final currentOptions = state.valueOrNull ?? const FilterOptions();
    final newPreset = FilterPreset(
      id: _uuid.v4(),
      name: name,
      filterState: filterState,
      createdAt: DateTime.now(),
    );

    final updatedPresets = [...currentOptions.savedPresets, newPreset];
    state = AsyncData(currentOptions.copyWith(savedPresets: updatedPresets));

    await _savePresets(updatedPresets);
  }

  Future<void> deletePreset(String presetId) async {
    final currentOptions = state.valueOrNull ?? const FilterOptions();
    final updatedPresets = currentOptions.savedPresets
        .where((preset) => preset.id != presetId)
        .toList();

    state = AsyncData(currentOptions.copyWith(savedPresets: updatedPresets));
    await _savePresets(updatedPresets);
  }

  Future<void> _savePresets(List<FilterPreset> presets) async {
    final jsonList = presets.map((preset) => preset.toJson()).toList();
    await _prefs.setString(_filterPresetsKey, jsonEncode(jsonList));
  }

  Future<void> updateAvailableTags(List<String> tags) async {
    final currentOptions = state.valueOrNull ?? const FilterOptions();
    state = AsyncData(currentOptions.copyWith(availableTags: tags));
    await _prefs.setStringList(_availableTagsKey, tags);
  }

  Future<void> addTag(String tag) async {
    final currentOptions = state.valueOrNull ?? const FilterOptions();
    if (!currentOptions.availableTags.contains(tag)) {
      final updatedTags = [...currentOptions.availableTags, tag];
      await updateAvailableTags(updatedTags);
    }
  }
}

// Provider for accessing current filter state synchronously
@riverpod
FilterState? currentFilterState(CurrentFilterStateRef ref) {
  return ref.watch(filterStateNotifierProvider).valueOrNull;
}

// Provider for accessing filter options synchronously
@riverpod
FilterOptions? currentFilterOptions(CurrentFilterOptionsRef ref) {
  return ref.watch(filterOptionsNotifierProvider).valueOrNull;
}