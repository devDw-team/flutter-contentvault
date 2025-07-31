import 'package:flutter/material.dart';

class FilterChipItem {
  final String value;
  final String label;
  final Widget? icon;

  const FilterChipItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class FilterChipGroup extends StatelessWidget {
  final List<FilterChipItem> items;
  final List<String> selectedValues;
  final Function(List<String>) onSelectionChanged;
  final bool allowMultiple;
  final int? maxSelection;

  const FilterChipGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.allowMultiple = true,
    this.maxSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedValues.contains(item.value);
        final canSelect = isSelected ||
            maxSelection == null ||
            selectedValues.length < maxSelection!;

        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                item.icon!,
                const SizedBox(width: 4),
              ],
              Text(item.label),
            ],
          ),
          onSelected: canSelect
              ? (selected) {
                  List<String> newSelection;
                  if (allowMultiple) {
                    if (selected) {
                      newSelection = [...selectedValues, item.value];
                    } else {
                      newSelection = selectedValues
                          .where((v) => v != item.value)
                          .toList();
                    }
                  } else {
                    newSelection = selected ? [item.value] : [];
                  }
                  onSelectionChanged(newSelection);
                }
              : null,
          showCheckmark: allowMultiple,
        );
      }).toList(),
    );
  }
}