import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import '../../providers/search_provider.dart';
import '../../domain/models/search_query_model.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchNotifierProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchNotifierProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Column(
        children: [
          _SearchInputSection(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              ref.read(searchNotifierProvider.notifier).search('');
            },
            isLoading: searchState.isLoading && searchState.results == null,
            suggestions: searchState.suggestions,
          ),
          _FilterChipsSection(
            selectedPlatforms: searchState.selectedPlatforms,
            onPlatformToggle: (platform) {
              ref.read(searchNotifierProvider.notifier).togglePlatformFilter(platform);
            },
            onClearFilters: () {
              ref.read(searchNotifierProvider.notifier).clearFilters();
            },
          ),
          Expanded(
            child: _buildContent(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState state) {
    if (state.hasError) {
      return _ErrorState(message: state.errorMessage ?? '오류가 발생했습니다');
    }

    if (state.isLoading && state.results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty && state.selectedPlatforms.isEmpty) {
      return _RecentSearches(
        onSearchTap: (query) {
          _searchController.text = query;
          ref.read(searchNotifierProvider.notifier).search(query);
        },
      );
    }

    if (state.results == null || state.results!.results.isEmpty) {
      return _NoResultsState(
        query: _searchController.text,
        suggestedQuery: state.results?.suggestedQuery,
        onSuggestionTap: (suggestion) {
          _searchController.text = suggestion;
          ref.read(searchNotifierProvider.notifier).search(suggestion);
        },
      );
    }

    return _SearchResultsList(
      results: state.results!,
      scrollController: _scrollController,
      isLoadingMore: state.isLoading,
    );
  }
}

class _SearchInputSection extends StatelessWidget {
  const _SearchInputSection({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isLoading,
    required this.suggestions,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isLoading;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: '제목, 내용, 작성자로 검색...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClear,
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        if (suggestions.isNotEmpty && focusNode.hasFocus)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Material(
              elevation: 4,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(suggestions[index]),
                    onTap: () {
                      controller.text = suggestions[index];
                      onChanged(suggestions[index]);
                      focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChipsSection extends StatelessWidget {
  const _FilterChipsSection({
    required this.selectedPlatforms,
    required this.onPlatformToggle,
    required this.onClearFilters,
  });

  final List<String> selectedPlatforms;
  final Function(String) onPlatformToggle;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final platforms = [
      ('전체', null),
      ('YouTube', 'youtube'),
      ('X/Twitter', 'twitter'),
      ('Threads', 'threads'),
      ('웹 기사', 'web'),
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...platforms.map((platform) {
            final isAllSelected = platform.$2 == null && selectedPlatforms.isEmpty;
            final isSelected = platform.$2 != null && selectedPlatforms.contains(platform.$2);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(platform.$1),
                selected: isAllSelected || isSelected,
                onSelected: (selected) {
                  if (platform.$2 == null) {
                    onClearFilters();
                  } else {
                    onPlatformToggle(platform.$2!);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onSearchTap});

  final ValueChanged<String> onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchHistory = ref.watch(searchHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 검색',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (searchHistory.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(clearSearchHistoryProvider.notifier).clear();
                  },
                  child: const Text('모두 지우기'),
                ),
            ],
          ),
        ),
        if (searchHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '검색 기록이 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: searchHistory.length,
              itemBuilder: (context, index) {
                final item = searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(item.query),
                  subtitle: Text('${item.resultCount}개 결과'),
                  onTap: () => onSearchTap(item.query),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.scrollController,
    required this.isLoadingMore,
  });

  final SearchResultsModel results;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '${results.totalCount}개 결과',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '(${results.searchDuration.toStringAsFixed(2)}초)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (results.relatedTags.isNotEmpty)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: results.relatedTags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(tag),
                    onDeleted: null,
                  ),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: results.results.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == results.results.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final result = results.results[index];
              return _SearchResultItem(result: result);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to content detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PlatformIcon(platform: result.sourcePlatform),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightedText(
                          text: result.title,
                          highlightedText: result.highlightedTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (result.author != null)
                          Text(
                            result.author!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.description != null || result.highlightedDescription != null) ...[
                const SizedBox(height: 8),
                _HighlightedText(
                  text: result.description ?? '',
                  highlightedText: result.highlightedDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                ),
              ],
              if (result.highlightedContent != null) ...[
                const SizedBox(height: 8),
                _HighlightedText(
                  text: '',
                  highlightedText: result.highlightedContent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(result.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  if (result.matchedFields.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${result.matchedFields.map(_translateField).join(', ')}에서 일치',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _translateField(String field) {
    switch (field) {
      case 'title':
        return '제목';
      case 'description':
        return '설명';
      case 'content':
        return '내용';
      default:
        return field;
    }
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.highlightedText,
    required this.style,
    this.maxLines,
  });

  final String text;
  final String? highlightedText;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (highlightedText == null || !highlightedText!.contains('<mark>')) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    // Parse HTML and create TextSpans
    final document = parse(highlightedText);
    final textSpans = <TextSpan>[];
    
    void processNode(node) {
      if (node.nodeType == 3) { // Text node
        textSpans.add(TextSpan(text: node.text));
      } else if (node.localName == 'mark') {
        textSpans.add(TextSpan(
          text: node.text,
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else {
        for (final child in node.nodes) {
          processNode(child);
        }
      }
    }

    for (final node in document.body?.nodes ?? []) {
      processNode(node);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: textSpans,
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (platform) {
      case 'youtube':
        icon = Icons.play_circle_filled;
        color = const Color(0xFFFF0000);
        break;
      case 'twitter':
        icon = Icons.chat_bubble;
        color = const Color(0xFF1DA1F2);
        break;
      case 'threads':
        icon = Icons.alternate_email;
        color = Colors.black;
        break;
      case 'article':
      case 'web':
        icon = Icons.article;
        color = const Color(0xFF4CAF50);
        break;
      default:
        icon = Icons.web;
        color = const Color(0xFF2196F3);
    }

    return Icon(icon, color: color, size: 20);
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({
    required this.query,
    required this.suggestedQuery,
    required this.onSuggestionTap,
  });

  final String query;
  final String? suggestedQuery;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '"$query"에 대한 검색 결과가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (suggestedQuery != null) ...[
              const SizedBox(height: 16),
              Text(
                '다음으로 검색해보세요:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onSuggestionTap(suggestedQuery!),
                child: Text(suggestedQuery!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '검색 중 오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}