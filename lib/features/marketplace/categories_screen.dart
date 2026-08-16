import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product.dart';
import '../../core/widgets/loading_views.dart';
import '../../services/catalog_service.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _catalog = CatalogService();
  List<MarketplaceCategory> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await _catalog.categories();
      if (mounted) setState(() { _categories = cats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Categories')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_categories.isEmpty) {
      return const EmptyView(
        icon: Icons.category_outlined,
        title: 'No categories found',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandOrange,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
        ),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) => _CategoryCell(category: _categories[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CategoryCell extends StatelessWidget {
  final MarketplaceCategory category;
  const _CategoryCell({required this.category});

  // Pick a color from a small palette so each cell has a tinted icon background.
  Color _accentColor(int id) {
    const palette = [
      Color(0xFFFF6F00), // orange
      Color(0xFF1E88E5), // blue
      Color(0xFF43A047), // green
      Color(0xFF8E24AA), // purple
      Color(0xFFE53935), // red
      Color(0xFF00897B), // teal
      Color(0xFFF4511E), // deep orange
      Color(0xFF3949AB), // indigo
    ];
    return palette[id % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(category.id);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialCategorySlug: category.slug,
            initialTitle: category.categoryName,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(child: Icon(Icons.category_outlined, color: accent, size: 28)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              category.categoryName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (category.prodCount != null && category.prodCount! > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${category.prodCount} products',
              style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
            ),
          ],
        ]),
      ),
    );
  }
}
