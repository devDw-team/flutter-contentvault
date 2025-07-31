import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/app_database.dart';
import '../domain/services/search_engine.dart';
import '../domain/models/search_query_model.dart';
import '../models/filter_state.dart';

part 'search_provider.freezed.dart';
part 'search_provider.g.dart';

// Search Engine Provider
final searchEngineProvider = Provider<SearchEngine>((ref) {
  final database = GetIt.instance<AppDatabase>();
  final engine = SearchEngine(database: database);
  
  // Load search history on initialization
  engine.loadSearchHistory();
  
  return engine;
});

// Search State
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    @Default(SearchQueryModel(query: '')) SearchQueryModel currentQuery,
    SearchResultsModel? results,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    String? errorMessage,
    @Default([]) List<String> suggestions,
    @Default([]) List<String> selectedPlatforms,
    @Default([]) List<String> selectedContentTypes,
    @Default([]) List<String> selectedTags,
  }) = _SearchState;
}

// Search Notifier
@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final SearchEngine _searchEngine;
  
  @override
  SearchState build() {
    _searchEngine = ref.watch(searchEngineProvider);
    return const SearchState();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty && state.selectedPlatforms.isEmpty) {
      // Clear results if query is empty and no filters
      state = state.copyWith(
        currentQuery: const SearchQueryModel(query: ''),
        results: null,
        suggestions: [],
      );
      return;
    }

    // Update current query
    final searchQuery = SearchQueryModel(
      query: query,
      platforms: state.selectedPlatforms,
      contentTypes: state.selectedContentTypes,
      tags: state.selectedTags,
      offset: 0,
      limit: 20,
    );

    state = state.copyWith(
      currentQuery: searchQuery,
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

    try {
      final results = await _searchEngine.search(searchQuery);
      
      // Get suggestions for the query
      final suggestions = query.length >= 2 
          ? await _searchEngine.getSuggestions(query)
          : <String>[];
      
      state = state.copyWith(
        results: results,
        isLoading: false,
        suggestions: suggestions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.results == null) return;
    
    final currentResults = state.results!;
    if (currentResults.results.length >= currentResults.totalCount) return;

    final newQuery = state.currentQuery.copyWith(
      offset: currentResults.results.length,
    );

    state = state.copyWith(isLoading: true);

    try {
      final moreResults = await _searchEngine.search(newQuery);
      
      state = state.copyWith(
        results: currentResults.copyWith(
          results: [...currentResults.results, ...moreResults.results],
          offset: newQuery.offset,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  void togglePlatformFilter(String platform) {
    final platforms = List<String>.from(state.selectedPlatforms);
    if (platforms.contains(platform)) {
      platforms.remove(platform);
    } else {
      platforms.add(platform);
    }
    
    state = state.copyWith(selectedPlatforms: platforms);
    
    // Re-run search with new filters
    if (state.currentQuery.query.isNotEmpty || platforms.isNotEmpty) {
      search(state.currentQuery.query);
    }
  }

  void toggleContentTypeFilter(String contentType) {
    final contentTypes = List<String>.from(state.selectedContentTypes);
    if (contentTypes.contains(contentType)) {
      contentTypes.remove(contentType);
    } else {
      contentTypes.add(contentType);
    }
    
    state = state.copyWith(selectedContentTypes: contentTypes);
    
    // Re-run search with new filters
    if (state.currentQuery.query.isNotEmpty || state.selectedPlatforms.isNotEmpty) {
      search(state.currentQuery.query);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      selectedPlatforms: [],
      selectedContentTypes: [],
      selectedTags: [],
    );
    
    // Re-run search without filters
    if (state.currentQuery.query.isNotEmpty) {
      search(state.currentQuery.query);
    } else {
      // Clear results if no query
      state = state.copyWith(results: null);
    }
  }

  void applyFilters(FilterState filterState) {
    state = state.copyWith(
      selectedPlatforms: filterState.contentTypes,
      selectedTags: filterState.tags,
    );
    
    // Update search query with all filter options
    final updatedQuery = state.currentQuery.copyWith(
      platforms: filterState.contentTypes,
      tags: filterState.tags,
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      sortBy: filterState.sortBy.value + (filterState.isAscending ? '_asc' : '_desc'),
    );
    
    state = state.copyWith(currentQuery: updatedQuery);
    
    // Re-run search with new filters
    search(state.currentQuery.query);
  }

  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    return await _searchEngine.getSuggestions(partialQuery);
  }
}

// Search History Provider
@riverpod
List<SearchHistoryModel> searchHistory(SearchHistoryRef ref) {
  final searchEngine = ref.watch(searchEngineProvider);
  return searchEngine.getSearchHistory();
}

// Clear Search History
@riverpod
class ClearSearchHistory extends _$ClearSearchHistory {
  @override
  FutureOr<void> build() {}

  Future<void> clear() async {
    state = const AsyncLoading();
    try {
      final searchEngine = ref.read(searchEngineProvider);
      await searchEngine.clearSearchHistory();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}