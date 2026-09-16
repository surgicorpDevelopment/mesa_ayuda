import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/date_format.dart';
import '../../theme/app_typography.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    if (!enabled || onChanged == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 8),
    );
    if (picked != null) onChanged!(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.textTheme.labelMedium),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.slate500),
              suffixIcon: value != null && enabled && onChanged != null
                  ? IconButton(
                      tooltip: 'Quitar fecha',
                      icon: const Icon(Icons.close, size: 18, color: AppColors.slate500),
                      onPressed: () => onChanged!(null),
                    )
                  : null,
            ),
            child: Text(
              formatDateShort(value, empty: 'Elegir fecha'),
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: value == null ? AppColors.slate500 : AppColors.slate900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
