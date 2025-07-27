import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class SavePage extends ConsumerStatefulWidget {
  const SavePage({super.key});

  @override
  ConsumerState<SavePage> createState() => _SavePageState();
}

class _SavePageState extends ConsumerState<SavePage> with TickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isUrlAnalyzed = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.mediumDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            title: const Text('콘텐츠 저장'),
            actions: [
              AnimatedSwitcher(
                duration: AppTheme.shortDuration,
                child: _isUrlAnalyzed
                    ? TextButton.icon(
                        key: const ValueKey('save_button'),
                        onPressed: _isLoading ? null : _saveContent,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('저장'),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              const SizedBox(width: AppTheme.space8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.space16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UrlInputSection(
                        controller: _urlController,
                        onAnalyze: _analyzeUrl,
                        isLoading: _isLoading,
                      ),
                      if (_isUrlAnalyzed) ...[
                        const SizedBox(height: AppTheme.space24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _ContentFormSection(
                                titleController: _titleController,
                                descriptionController: _descriptionController,
                              ),
                              const SizedBox(height: AppTheme.space24),
                              const _TagsSection(),
                              const SizedBox(height: AppTheme.space24),
                              const _FoldersSection(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeUrl() async {
    if (!_validateUrl()) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // TODO: URL 분석 로직 구현
      await Future.delayed(const Duration(seconds: 2)); // 임시 딜레이
      
      // 임시 데이터 설정
      _titleController.text = '분석된 제목';
      _descriptionController.text = '분석된 설명';
      
      setState(() {
        _isUrlAnalyzed = true;
      });
      
      _fadeController.forward();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('URL 분석이 완료되었습니다'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL 분석 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // TODO: 콘텐츠 저장 로직 구현
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('콘텐츠가 저장되었습니다'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: '보기',
              onPressed: () {
                // TODO: 저장된 콘텐츠로 이동
              },
            ),
          ),
        );
        
        // 폼 초기화
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _validateUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 입력해주세요')),
      );
      return false;
    }
    
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$'
    );
    
    if (!urlPattern.hasMatch(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 URL 형식이 아닙니다')),
      );
      return false;
    }
    
    return true;
  }
  
  void _resetForm() {
    _urlController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _fadeController.reverse().then((_) {
      setState(() {
        _isUrlAnalyzed = false;
      });
    });
  }
}

class _UrlInputSection extends StatelessWidget {
  const _UrlInputSection({
    required this.controller,
    required this.onAnalyze,
    required this.isLoading,
  });

  final TextEditingController controller;
  final VoidCallback onAnalyze;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'URL 입력',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: controller.clear,
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onAnalyze(),
          ),
          const SizedBox(height: AppTheme.space16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onAnalyze,
              icon: AnimatedSwitcher(
                duration: AppTheme.shortDuration,
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics_rounded, key: ValueKey('icon')),
              ),
              label: Text(isLoading ? '분석 중...' : 'URL 분석'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentFormSection extends StatelessWidget {
  const _ContentFormSection({
    required this.titleController,
    required this.descriptionController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                '콘텐츠 정보',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '제목',
              hintText: '콘텐츠 제목을 입력하세요',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
              hintText: '콘텐츠 설명을 입력하세요 (선택사항)',
              prefixIcon: Icon(Icons.description_rounded),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _TagsSection extends ConsumerStatefulWidget {
  const _TagsSection();

  @override
  ConsumerState<_TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends ConsumerState<_TagsSection> {
  final List<String> _selectedTags = ['기술', 'Flutter'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: const Icon(
                      Icons.label_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    '태그',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddTagDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              ..._selectedTags.map((tag) => Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                  HapticFeedback.lightImpact();
                },
              )),
              ActionChip(
                label: const Text('AI 추천'),
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                onPressed: () {
                  // TODO: AI 태그 추천 기능
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '태그 추가',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              TextField(
                decoration: const InputDecoration(
                  hintText: '태그 이름',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _selectedTags.add(value.trim());
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldersSection extends ConsumerStatefulWidget {
  const _FoldersSection();

  @override
  ConsumerState<_FoldersSection> createState() => _FoldersSectionState();
}

class _FoldersSectionState extends ConsumerState<_FoldersSection> {
  String? _selectedFolder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                '폴더',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          DropdownButtonFormField<String>(
            value: _selectedFolder,
            decoration: const InputDecoration(
              hintText: '폴더를 선택하세요',
              prefixIcon: Icon(Icons.folder_open_rounded),
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('일반')),
              DropdownMenuItem(value: '2', child: Text('즐겨찾기')),
              DropdownMenuItem(value: '3', child: Text('나중에 읽기')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFolder = value;
              });
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }
}