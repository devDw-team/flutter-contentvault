import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/search_query_model.dart';

class SearchEngine {
  final AppDatabase _database;
  final _uuid = const Uuid();
  
  // Cache for search history
  final List<SearchHistoryModel> _searchHistory = [];
  static const int _maxHistoryItems = 30;
  
  SearchEngine({required AppDatabase database}) : _database = database;

  Future<SearchResultsModel> search(SearchQueryModel query) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Validate query
      if (query.query.trim().length < 2 && query.query.isNotEmpty) {
        return SearchResultsModel(
          results: [],
          totalCount: 0,
          offset: query.offset,
          limit: query.limit,
          searchDuration: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // If empty query, return recent contents
      if (query.query.isEmpty) {
        return await _getRecentContents(query, stopwatch);
      }

      // Preprocess search query
      final processedQuery = _preprocessQuery(query.query);
      
      // Build and execute FTS query
      final results = await _executeFtsSearch(processedQuery, query);
      
      // Add to search history
      await _addToSearchHistory(query, results.length);
      
      stopwatch.stop();
      
      return SearchResultsModel(
        results: results,
        totalCount: results.length,
        offset: query.offset,
        limit: query.limit,
        searchDuration: stopwatch.elapsedMilliseconds / 1000.0,
        suggestedQuery: _getSuggestedQuery(query.query, results.length),
        relatedTags: await _getRelatedTags(results),
      );
    } catch (e) {
      debugPrint('SearchEngine: Error during search: $e');
      stopwatch.stop();
      
      return SearchResultsModel(
        results: [],
        totalCount: 0,
        offset: query.offset,
        limit: query.limit,
        searchDuration: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  String _preprocessQuery(String query) {
    // Clean and normalize query
    query = query.trim().toLowerCase();
    
    // Handle special characters for FTS5
    query = query.replaceAll('"', '""');
    
    // For Korean text, keep as is
    // For English, add wildcards for partial matching
    if (!_containsKorean(query)) {
      // Split into words and add wildcards
      final words = query.split(' ').where((w) => w.isNotEmpty);
      return words.map((word) => '$word*').join(' ');
    }
    
    return query;
  }

  bool _containsKorean(String text) {
    return RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(text);
  }

  Future<List<SearchResultModel>> _executeFtsSearch(
    String processedQuery,
    SearchQueryModel query,
  ) async {
    // Build FTS5 match expression
    String matchExpression = processedQuery;
    
    // Build SQL query with FTS5
    final sql = StringBuffer();
    sql.write('''
      SELECT 
        c.id,
        c.title,
        c.url,
        c.description,
        c.thumbnail_url,
        c.content_type,
        c.source_platform,
        c.author,
        c.published_at,
        c.created_at,
        c.content_text,
        bm25(contents_fts) as rank,
        snippet(contents_fts, 1, '<mark>', '</mark>', '...', 20) as highlighted_title,
        snippet(contents_fts, 2, '<mark>', '</mark>', '...', 30) as highlighted_description,
        snippet(contents_fts, 3, '<mark>', '</mark>', '...', 40) as highlighted_content
      FROM contents_table c
      INNER JOIN contents_fts ON c.id = contents_fts.content_id
      WHERE contents_fts MATCH ?
    ''');
    
    // Add platform filter
    if (query.platforms.isNotEmpty) {
      sql.write(' AND c.source_platform IN (${query.platforms.map((_) => '?').join(',')})');
    }
    
    // Add content type filter
    if (query.contentTypes.isNotEmpty) {
      sql.write(' AND c.content_type IN (${query.contentTypes.map((_) => '?').join(',')})');
    }
    
    // Add date filters
    if (query.startDate != null) {
      sql.write(' AND c.created_at >= ?');
    }
    if (query.endDate != null) {
      sql.write(' AND c.created_at <= ?');
    }
    
    // Add sorting
    switch (query.sortBy) {
      case 'date_desc':
        sql.write(' ORDER BY c.created_at DESC');
        break;
      case 'date_asc':
        sql.write(' ORDER BY c.created_at ASC');
        break;
      default:
        sql.write(' ORDER BY rank');
    }
    
    // Add pagination
    sql.write(' LIMIT ? OFFSET ?');
    
    // Prepare parameters
    final params = <Variable<Object>>[];
    params.add(Variable.withString(matchExpression));
    params.addAll(query.platforms.map((p) => Variable.withString(p)));
    params.addAll(query.contentTypes.map((t) => Variable.withString(t)));
    if (query.startDate != null) {
      params.add(Variable.withString(query.startDate!.toIso8601String()));
    }
    if (query.endDate != null) {
      params.add(Variable.withString(query.endDate!.toIso8601String()));
    }
    params.add(Variable.withInt(query.limit));
    params.add(Variable.withInt(query.offset));
    
    // Execute query
    final result = await _database.customSelect(sql.toString(), variables: params).get();
    
    // Convert to SearchResultModel
    return result.map((row) {
      final matchedFields = <String>[];
      if (row.read<String?>('highlighted_title')?.contains('<mark>') ?? false) {
        matchedFields.add('title');
      }
      if (row.read<String?>('highlighted_description')?.contains('<mark>') ?? false) {
        matchedFields.add('description');
      }
      if (row.read<String?>('highlighted_content')?.contains('<mark>') ?? false) {
        matchedFields.add('content');
      }
      
      return SearchResultModel(
        contentId: row.read<String>('id'),
        title: row.read<String>('title'),
        url: row.read<String>('url'),
        description: row.read<String?>('description'),
        thumbnailUrl: row.read<String?>('thumbnail_url'),
        contentType: row.read<String>('content_type'),
        sourcePlatform: row.read<String>('source_platform'),
        author: row.read<String?>('author'),
        publishedAt: row.read<DateTime?>('published_at'),
        createdAt: row.read<DateTime>('created_at'),
        relevanceScore: row.read<double>('rank').abs(), // BM25 scores are negative
        highlightedTitle: row.read<String?>('highlighted_title'),
        highlightedDescription: row.read<String?>('highlighted_description'),
        highlightedContent: row.read<String?>('highlighted_content'),
        matchedFields: matchedFields,
      );
    }).toList();
  }

  Future<SearchResultsModel> _getRecentContents(
    SearchQueryModel query,
    Stopwatch stopwatch,
  ) async {
    final queryBuilder = _database.select(_database.contentsTable);
    
    // Apply filters
    if (query.platforms.isNotEmpty) {
      queryBuilder.where((tbl) => tbl.sourcePlatform.isIn(query.platforms));
    }
    
    // Sort by date
    queryBuilder.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    
    // Apply pagination
    queryBuilder.limit(query.limit, offset: query.offset);
    
    final contents = await queryBuilder.get();
    
    final results = contents.map((content) => SearchResultModel(
      contentId: content.id,
      title: content.title,
      url: content.url,
      description: content.description,
      thumbnailUrl: content.thumbnailUrl,
      contentType: content.contentType,
      sourcePlatform: content.sourcePlatform,
      author: content.author,
      publishedAt: content.publishedAt,
      createdAt: content.createdAt,
      relevanceScore: 0.0,
      highlightedTitle: null,
      highlightedDescription: null,
      highlightedContent: null,
      matchedFields: [],
    )).toList();
    
    stopwatch.stop();
    
    return SearchResultsModel(
      results: results,
      totalCount: results.length,
      offset: query.offset,
      limit: query.limit,
      searchDuration: stopwatch.elapsedMilliseconds / 1000.0,
    );
  }

  Future<void> _addToSearchHistory(SearchQueryModel query, int resultCount) async {
    if (query.query.isEmpty) return;
    
    final historyItem = SearchHistoryModel(
      id: _uuid.v4(),
      query: query.query,
      searchedAt: DateTime.now(),
      resultCount: resultCount,
      filters: {
        if (query.platforms.isNotEmpty) 'platforms': query.platforms,
        if (query.contentTypes.isNotEmpty) 'contentTypes': query.contentTypes,
        if (query.tags.isNotEmpty) 'tags': query.tags,
      },
    );
    
    // Add to history
    _searchHistory.insert(0, historyItem);
    
    // Keep only last N items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
    
    // Save to database
    await _database.into(_database.searchHistoryTable).insert(
      SearchHistoryTableCompanion.insert(
        query: historyItem.query,
        resultCount: Value(historyItem.resultCount),
        filters: Value(jsonEncode(historyItem.filters)),
        searchedAt: historyItem.searchedAt,
      ),
    );
  }

  String? _getSuggestedQuery(String originalQuery, int resultCount) {
    if (resultCount > 0) return null;
    
    // Simple typo correction suggestions
    // In production, use a proper spell checker or fuzzy matching
    final suggestions = <String>[];
    
    // Remove last character (typo)
    if (originalQuery.length > 3) {
      suggestions.add(originalQuery.substring(0, originalQuery.length - 1));
    }
    
    // Common typos for Korean
    final koreanTypos = {
      'ㅐ': 'ㅔ',
      'ㅔ': 'ㅐ',
      'ㅗ': 'ㅓ',
      'ㅓ': 'ㅗ',
    };
    
    for (final entry in koreanTypos.entries) {
      if (originalQuery.contains(entry.key)) {
        suggestions.add(originalQuery.replaceAll(entry.key, entry.value));
      }
    }
    
    return suggestions.isNotEmpty ? suggestions.first : null;
  }

  Future<List<String>> _getRelatedTags(List<SearchResultModel> results) async {
    if (results.isEmpty) return [];
    
    // Extract tags from results
    final tagCounts = <String, int>{};
    
    for (final result in results.take(10)) {
      // Get tags for this content
      final contentTags = await (_database
          .select(_database.contentTagsTable)
          .join([
            innerJoin(
              _database.tagsTable,
              _database.tagsTable.id.equalsExp(_database.contentTagsTable.tagId),
            ),
          ])
          ..where(_database.contentTagsTable.contentId.equals(result.contentId)))
          .get();
      
      for (final row in contentTags) {
        final tag = row.readTable(_database.tagsTable);
        tagCounts[tag.name] = (tagCounts[tag.name] ?? 0) + 1;
      }
    }
    
    // Sort by count and return top tags
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(5).map((e) => e.key).toList();
  }

  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    // Get suggestions from search history
    final historySuggestions = _searchHistory
        .where((item) => item.query.toLowerCase().contains(partialQuery.toLowerCase()))
        .map((item) => item.query)
        .take(5)
        .toList();
    
    // Get suggestions from content titles
    final titleSuggestions = await _database.customSelect(
      '''
      SELECT DISTINCT title 
      FROM contents_table 
      WHERE LOWER(title) LIKE ? 
      ORDER BY created_at DESC 
      LIMIT 5
      ''',
      variables: [Variable.withString('%${partialQuery.toLowerCase()}%')],
    ).get();
    
    final suggestions = <String>{};
    suggestions.addAll(historySuggestions);
    suggestions.addAll(titleSuggestions.map((row) => row.read<String>('title')));
    
    return suggestions.take(10).toList();
  }

  List<SearchHistoryModel> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    
    // Clear from database
    await _database.delete(_database.searchHistoryTable).go();
  }

  Future<void> loadSearchHistory() async {
    final history = await (_database.select(_database.searchHistoryTable)
      ..orderBy([(t) => OrderingTerm(expression: t.searchedAt, mode: OrderingMode.desc)])
      ..limit(_maxHistoryItems))
      .get();
    
    _searchHistory.clear();
    _searchHistory.addAll(
      history.map((row) => SearchHistoryModel(
        id: _uuid.v4(),
        query: row.query,
        searchedAt: row.searchedAt,
        resultCount: row.resultCount,
        filters: row.filters != null ? jsonDecode(row.filters!) : null,
      )),
    );
  }
}