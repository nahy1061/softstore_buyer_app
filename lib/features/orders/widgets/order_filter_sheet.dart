import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';

class OrderFilterSheet extends StatefulWidget {
  final List<OrderStatus> currentStatusFilters;
  final OrderSortOption currentSortOption;
  final DateTime? currentDateFrom;
  final DateTime? currentDateTo;

  const OrderFilterSheet({
    super.key,
    required this.currentStatusFilters,
    required this.currentSortOption,
    this.currentDateFrom,
    this.currentDateTo,
  });

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  late List<OrderStatus> _selectedStatuses;
  late OrderSortOption _selectedSort;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = List.from(widget.currentStatusFilters);
    _selectedSort = widget.currentSortOption;
    _dateFrom = widget.currentDateFrom;
    _dateTo = widget.currentDateTo;
  }

  void _toggleStatus(OrderStatus status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _applyFilters() {
    context.read<OrderCubit>().updateStatusFilters(_selectedStatuses);
    context.read<OrderCubit>().updateSortOption(_selectedSort);
    context.read<OrderCubit>().updateDateRange(from: _dateFrom, to: _dateTo);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _selectedStatuses = [];
      _selectedSort = OrderSortOption.newestFirst;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Filter Orders',
                    style: AppTypography.sectionHeading.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Clear all',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  _SectionTitle(title: 'Sort By'),
                  const SizedBox(height: AppSpacing.sm),
                  _SortOptions(
                    selected: _selectedSort,
                    onChanged: (sort) => setState(() => _selectedSort = sort),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Status
                  _SectionTitle(title: 'Status'),
                  const SizedBox(height: AppSpacing.sm),
                  _StatusChips(
                    selected: _selectedStatuses,
                    onToggle: _toggleStatus,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Date Range
                  _SectionTitle(title: 'Date Range'),
                  const SizedBox(height: AppSpacing.sm),
                  _DateRangePicker(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    onPickFrom: () => _pickDate(isFrom: true),
                    onPickTo: () => _pickDate(isFrom: false),
                    onClearFrom: () => setState(() => _dateFrom = null),
                    onClearTo: () => setState(() => _dateTo = null),
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.radiusSm,
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: AppTypography.buttonText.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SortOptions extends StatelessWidget {
  final OrderSortOption selected;
  final ValueChanged<OrderSortOption> onChanged;

  const _SortOptions({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: OrderSortOption.values.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option.label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final List<OrderStatus> selected;
  final ValueChanged<OrderStatus> onToggle;

  const _StatusChips({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: OrderStatus.values.map((status) {
        final isSelected = selected.contains(status);
        return GestureDetector(
          onTap: () => onToggle(status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? status.bgColor : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? status.borderColor : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.icon,
                  size: 14,
                  color: isSelected ? status.color : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  status.shortLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? status.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearFrom;
  final VoidCallback onClearTo;

  const _DateRangePicker({
    required this.dateFrom,
    required this.dateTo,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearFrom,
    required this.onClearTo,
  });

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateButton(
            label: 'From',
            date: dateFrom,
            onTap: onPickFrom,
            onClear: dateFrom != null ? onClearFrom : null,
            format: _formatDate,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textDisabled),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DateButton(
            label: 'To',
            date: dateTo,
            onTap: onPickTo,
            onClear: dateTo != null ? onClearTo : null,
            format: _formatDate,
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String Function(DateTime) format;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: date != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                  Text(
                    date != null ? format(date!) : 'Select date',
                    style: AppTypography.bodySmall.copyWith(
                      color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
