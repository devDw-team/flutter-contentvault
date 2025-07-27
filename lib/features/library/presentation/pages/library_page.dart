import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('라이브러리'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              // TODO: 정렬 로직 구현
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('최신순'),
              ),
              const PopupMenuItem(
                value: 'date_asc',
                child: Text('오래된순'),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Text('제목순'),
              ),
              const PopupMenuItem(
                value: 'platform',
                child: Text('플랫폼별'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '폴더'),
            Tab(text: '태그'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllContentTab(isGridView: _isGridView),
          const _FoldersTab(),
          const _TagsTab(),
        ],
      ),
    );
  }
}

class _AllContentTab extends StatelessWidget {
  const _AllContentTab({required this.isGridView});

  final bool isGridView;

  @override
  Widget build(BuildContext context) {
    // 임시로 빈 상태 표시
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 콘텐츠가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 콘텐츠를 저장해보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 저장 페이지로 이동
            },
            icon: const Icon(Icons.add),
            label: const Text('콘텐츠 저장하기'),
          ),
        ],
      ),
    );
  }
}

class _FoldersTab extends StatelessWidget {
  const _FoldersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _FolderCard(
          name: '일반',
          icon: Icons.folder,
          color: Colors.blue,
          contentCount: 0,
          onTap: () {
            // TODO: 폴더 내용 보기
          },
        ),
        const SizedBox(height: 12),
        _FolderCard(
          name: '즐겨찾기',
          icon: Icons.star,
          color: Colors.orange,
          contentCount: 0,
          onTap: () {
            // TODO: 폴더 내용 보기
          },
        ),
        const SizedBox(height: 12),
        _FolderCard(
          name: '나중에 읽기',
          icon: Icons.schedule,
          color: Colors.green,
          contentCount: 0,
          onTap: () {
            // TODO: 폴더 내용 보기
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add),
            ),
            title: const Text('새 폴더 만들기'),
            subtitle: const Text('콘텐츠를 정리할 새 폴더를 만드세요'),
            onTap: () {
              // TODO: 폴더 생성 다이얼로그
            },
          ),
        ),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.contentCount,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final int contentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(name),
        subtitle: Text('${contentCount}개 콘텐츠'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _TagsTab extends StatelessWidget {
  const _TagsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '태그 목록',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: 태그 관리 페이지로 이동
                },
                icon: const Icon(Icons.edit),
                label: const Text('관리'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(
                  label: '기술',
                  color: Colors.blue,
                  count: 0,
                ),
                _TagChip(
                  label: '뉴스',
                  color: Colors.red,
                  count: 0,
                ),
                _TagChip(
                  label: '교육',
                  color: Colors.green,
                  count: 0,
                ),
                _TagChip(
                  label: '엔터테인먼트',
                  color: Colors.purple,
                  count: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
      label: Text('$label ($count)'),
      onPressed: () {
        // TODO: 태그별 콘텐츠 보기
      },
    );
  }
} 