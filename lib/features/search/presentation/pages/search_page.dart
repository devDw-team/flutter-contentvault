import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Column(
        children: [
          _SearchInputSection(
            controller: _searchController,
            onSearch: _performSearch,
            isSearching: _isSearching,
          ),
          const _FilterChipsSection(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                    ? const _EmptySearchState()
                    : const _SearchResultsSection(),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: 검색 로직 구현
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}

class _SearchInputSection extends StatelessWidget {
  const _SearchInputSection({
    required this.controller,
    required this.onSearch,
    required this.isSearching,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: '콘텐츠를 검색하세요...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isSearching
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
                      onPressed: () {
                        controller.clear();
                      },
                    )
                  : null,
        ),
        onSubmitted: (_) => onSearch(),
        onChanged: (value) {
          if (value.isNotEmpty) {
            onSearch();
          }
        },
      ),
    );
  }
}

class _FilterChipsSection extends StatelessWidget {
  const _FilterChipsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('전체'),
            selected: true,
            onSelected: (selected) {
              // TODO: 필터 처리
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('YouTube'),
            selected: false,
            onSelected: (selected) {
              // TODO: 필터 처리
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('웹 기사'),
            selected: false,
            onSelected: (selected) {
              // TODO: 필터 처리
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Twitter'),
            selected: false,
            onSelected: (selected) {
              // TODO: 필터 처리
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('즐겨찾기'),
            selected: false,
            onSelected: (selected) {
              // TODO: 필터 처리
            },
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '콘텐츠를 검색해보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '제목, 설명, 태그로 검색할 수 있습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5, // 임시 데이터
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article),
            ),
            title: Text('검색 결과 ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('검색된 콘텐츠의 설명입니다...'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    Chip(
                      label: const Text('기술'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: const Text('Flutter'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                // TODO: 즐겨찾기 토글
              },
            ),
            onTap: () {
              // TODO: 콘텐츠 상세 페이지로 이동
            },
          ),
        );
      },
    );
  }
} 