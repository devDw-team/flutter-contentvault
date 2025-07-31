import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 M월 d일', 'ko_KR');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: '시작일',
                date: startDate,
                onDateSelected: (date) {
                  if (endDate != null && date != null && date.isAfter(endDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('시작일은 종료일 이전이어야 합니다'),
                      ),
                    );
                    return;
                  }
                  onDateRangeChanged(date, endDate);
                },
                maxDate: endDate ?? DateTime.now(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DateField(
                label: '종료일',
                date: endDate,
                onDateSelected: (date) {
                  if (startDate != null && date != null && date.isBefore(startDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('종료일은 시작일 이후여야 합니다'),
                      ),
                    );
                    return;
                  }
                  onDateRangeChanged(startDate, date);
                },
                minDate: startDate,
                maxDate: DateTime.now(),
              ),
            ),
          ],
        ),
        if (startDate != null || endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  _getDateRangeText(dateFormat),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onDateRangeChanged(null, null),
                  child: const Text('지우기'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getDateRangeText(DateFormat format) {
    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays;
      return '${format.format(startDate!)} - ${format.format(endDate!)} ($days일)';
    } else if (startDate != null) {
      return '${format.format(startDate!)}부터';
    } else if (endDate != null) {
      return '${format.format(endDate!)}까지';
    }
    return '';
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime?) onDateSelected;
  final DateTime? minDate;
  final DateTime? maxDate;

  const _DateField({
    required this.label,
    this.date,
    required this.onDateSelected,
    this.minDate,
    this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 M월 d일', 'ko_KR');

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? dateFormat.format(date!) : '날짜 선택',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: minDate ?? DateTime(2020),
      lastDate: maxDate ?? DateTime.now(),
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}