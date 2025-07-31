import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contentvault/features/search/models/filter_state.dart';
import 'package:flutter_contentvault/features/search/models/filter_options.dart';
import 'package:flutter_contentvault/features/search/presentation/widgets/filter_chip_group.dart';
import 'package:flutter_contentvault/features/search/presentation/widgets/date_range_selector.dart';
import 'package:flutter_contentvault/features/search/providers/filter_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final FilterState initialState;
  final FilterOptions options;
  final Function(FilterState) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialState,
    required this.options,
    required this.onApply,
  });

  static Future<FilterState?> show(
    BuildContext context, {
    required FilterState initialState,
    required FilterOptions options,
  }) async {
    return showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialState: initialState,
        options: options,
        onApply: (state) => Navigator.of(context).pop(state),
      ),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late FilterState _currentState;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  void _updateState(FilterState newState) {
    setState(() {
      _currentState = newState;
      _validationError = newState.validateFilters();
    });
  }

  void _handleContentTypeSelection(List<String> selected) {
    _updateState(_currentState.copyWith(contentTypes: selected));
  }

  void _handleTagSelection(List<String> selected) {
    if (selected.length <= 5) {
      _updateState(_currentState.copyWith(tags: selected));
    } else {
      setState(() {
        _validationError = '최대 5개의 태그만 선택할 수 있습니다';
      });
    }
  }

  void _handleDateRangeUpdate(DateTime? start, DateTime? end) {
    _updateState(_currentState.copyWith(
      startDate: start,
      endDate: end,
    ));
  }

  void _handleSortByChange(SortBy? sortBy) {
    if (sortBy != null) {
      _updateState(_currentState.copyWith(sortBy: sortBy));
    }
  }

  void _handleReset() {
    _updateState(_currentState.copyWithReset());
  }

  void _handleApply() {
    if (_validationError == null) {
      widget.onApply(_currentState);
      ref.read(filterStateNotifierProvider.notifier).updateFilters(_currentState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = _currentState.activeFilterCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, activeCount),
          if (_validationError != null) _buildErrorBanner(theme),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentTypeSection(theme),
                  const SizedBox(height: 24),
                  _buildTagsSection(theme),
                  const SizedBox(height: 24),
                  _buildDateRangeSection(theme),
                  const SizedBox(height: 24),
                  _buildSortBySection(theme),
                  if (widget.options.savedPresets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildPresetsSection(theme),
                  ],
                ],
              ),
            ),
          ),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int activeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '검색 필터',
            style: theme.textTheme.titleLarge,
          ),
          if (activeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeCount',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '콘텐츠 타입',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilterChipGroup(
          items: widget.options.availableContentTypes
              .map((type) => FilterChipItem(
                    value: type,
                    label: ContentTypeFilter.getDisplayName(type),
                    icon: Text(ContentTypeFilter.getIcon(type)),
                  ))
              .toList(),
          selectedValues: _currentState.contentTypes,
          onSelectionChanged: _handleContentTypeSelection,
          allowMultiple: true,
        ),
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '태그',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${_currentState.tags.length}/5)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilterChipGroup(
          items: widget.options.availableTags
              .map((tag) => FilterChipItem(
                    value: tag,
                    label: tag,
                  ))
              .toList(),
          selectedValues: _currentState.tags,
          onSelectionChanged: _handleTagSelection,
          allowMultiple: true,
          maxSelection: 5,
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 범위',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DateRangeSelector(
          startDate: _currentState.startDate,
          endDate: _currentState.endDate,
          onDateRangeChanged: _handleDateRangeUpdate,
        ),
      ],
    );
  }

  Widget _buildSortBySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정렬 기준',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SortBy>(
          value: _currentState.sortBy,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: SortBy.values
              .map((sortBy) => DropdownMenuItem(
                    value: sortBy,
                    child: Text(sortBy.displayName),
                  ))
              .toList(),
          onChanged: _handleSortByChange,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('정렬 순서:'),
            const SizedBox(width: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('내림차순'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('오름차순'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_currentState.isAscending},
              onSelectionChanged: (values) {
                _updateState(_currentState.copyWith(
                  isAscending: values.first,
                ));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '저장된 필터',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.options.savedPresets
              .map((preset) => ActionChip(
                    label: Text(preset.name),
                    onPressed: () => _updateState(preset.filterState),
                    backgroundColor: preset.isDefault
                        ? theme.colorScheme.primaryContainer
                        : null,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _handleReset,
            child: const Text('초기화'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _validationError == null ? _handleApply : null,
            child: Text(
              '필터 적용 (${_currentState.activeFilterCount})',
            ),
          ),
        ],
      ),
    );
  }
}