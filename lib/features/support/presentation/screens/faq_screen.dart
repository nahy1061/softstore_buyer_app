import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../models/faq_model.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter categories and items by search query
  List<FaqCategory> get _filtered {
    if (_query.trim().isEmpty) return kFaqData;
    final q = _query.toLowerCase();
    final results = <FaqCategory>[];
    for (final category in kFaqData) {
      final matchingItems = category.items
          .where((item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q))
          .toList();
      if (matchingItems.isNotEmpty) {
        results.add(FaqCategory(title: category.title, items: matchingItems));
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          'Help Centre',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search help articles...',
                hintStyle: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textDisabled),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // FAQ list or empty state
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    itemCount: filtered.length + 1, // +1 for bottom CTA
                    itemBuilder: (context, index) {
                      if (index == filtered.length) return _buildBottomCta(context);
                      return _FaqCategorySection(category: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No results for "$_query"',
              style: AppTypography.sectionHeading
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try a different keyword, or contact us directly.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha:0.06),
        borderRadius: AppDimensions.radiusLg,
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Still need help?',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Our support team replies to every ticket — usually within a few hours.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.radiusMd),
              ),
              child: const Text('Contact Support'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCategorySection extends StatelessWidget {
  final FaqCategory category;

  const _FaqCategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Text(
            category.title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDimensions.radiusLg,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < category.items.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, indent: AppSpacing.lg, color: AppColors.divider),
                _FaqItemTile(item: category.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItemTile extends StatefulWidget {
  final FaqItem item;

  const _FaqItemTile({required this.item});

  @override
  State<_FaqItemTile> createState() => _FaqItemTileState();
}

class _FaqItemTileState extends State<_FaqItemTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurn = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: AppDimensions.radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RotationTransition(
                  turns: _iconTurn,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.item.answer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
