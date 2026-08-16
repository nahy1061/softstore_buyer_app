import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/loading_views.dart';
import '../../services/catalog_service.dart';
import 'product_detail_screen.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class SearchProvider extends ChangeNotifier {
  final _catalog = CatalogService();

  List<Product> _products = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  String sort = 'newest';
  bool inStockOnly = false;
  double? minPrice;
  double? maxPrice;
  int? minRating;
  String query = '';
  String? categorySlug;

  List<Product> get products => _products;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get canLoadMore => _page < _totalPages;
  bool get hasActiveFilters => sort != 'newest' || inStockOnly || minPrice != null || maxPrice != null;

  Future<void> search({bool reset = true}) async {
    if (reset) {
      _loading = true;
      _error = null;
      _page = 1;
      _products = [];
      notifyListeners();
    } else {
      if (_loadingMore || _page >= _totalPages) return;
      _page++;
      _loadingMore = true;
      notifyListeners();
    }

    try {
      final res = await _catalog.search(
        query: query,
        categorySlug: categorySlug,
        sort: sort,
        page: _page,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        inStockOnly: inStockOnly,
      );
      if (reset) {
        _products = res.products;
      } else {
        _products = [..._products, ...res.products];
      }
      _totalPages = res.totalPages;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  void applyFilters({
    required String newSort,
    required bool newInStock,
    required double? newMinPrice,
    required double? newMaxPrice,
    int? newMinRating,
  }) {
    sort = newSort;
    inStockOnly = newInStock;
    minPrice = newMinPrice;
    maxPrice = newMaxPrice;
    minRating = newMinRating;
    search();
  }

  void clearFilters() {
    sort = 'newest';
    inStockOnly = false;
    minPrice = null;
    maxPrice = null;
    minRating = null;
    search();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  final String? initialCategorySlug;
  final String? initialTitle;

  const SearchScreen({super.key, this.initialCategorySlug, this.initialTitle});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchProvider _provider;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _provider = SearchProvider()
      ..categorySlug = widget.initialCategorySlug
      ..search();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 250) {
      _provider.search(reset: false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: _provider,
        child: const _FilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              onChanged: (v) => _provider.query = v,
              onSubmitted: (_) => _provider.search(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: widget.initialCategorySlug != null
                    ? 'Search in ${widget.initialTitle ?? widget.initialCategorySlug}...'
                    : 'Search products...',
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _searchCtrl,
                  builder: (_, v, __) => v.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            _provider.query = '';
                            _provider.search();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          actions: [
            Consumer<SearchProvider>(
              builder: (_, p, __) => IconButton(
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.tune, color: Colors.white),
                  if (p.hasActiveFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.brandAmber, shape: BoxShape.circle),
                      ),
                    ),
                ]),
                onPressed: _showFilterSheet,
              ),
            ),
          ],
        ),
        body: Column(children: [
          // Active filter chips row
          Consumer<SearchProvider>(
            builder: (_, p, __) => p.hasActiveFilters
                ? _ActiveFiltersRow(provider: p)
                : const SizedBox.shrink(),
          ),
          Expanded(child: _buildBody()),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<SearchProvider>(
      builder: (ctx, p, _) {
        if (p.loading) return const LoadingView();
        if (p.error != null) {
          return ErrorView(message: p.error!, onRetry: p.search);
        }
        if (p.products.isEmpty) {
          return EmptyView(
            icon: Icons.search_off_outlined,
            title: 'No products found',
            subtitle: 'Try different keywords or remove some filters.',
            action: p.hasActiveFilters
                ? TextButton(
                    onPressed: p.clearFilters,
                    child: const Text('Clear Filters'),
                  )
                : null,
          );
        }

        return GridView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemCount: p.products.length + (p.loadingMore ? 2 : 0),
          itemBuilder: (ctx, i) {
            if (i >= p.products.length) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brandOrange, strokeWidth: 2));
            }
            final prod = p.products[i];
            return ProductCard(
              product: prod,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: prod.slug ?? '${prod.id}')),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Active filters strip
// ---------------------------------------------------------------------------

class _ActiveFiltersRow extends StatelessWidget {
  final SearchProvider provider;
  const _ActiveFiltersRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              if (provider.sort != 'newest') _Chip(label: _sortLabel(provider.sort)),
              if (provider.inStockOnly) const _Chip(label: 'In Stock'),
              if (provider.minPrice != null || provider.maxPrice != null)
                _Chip(
                  label: 'PKR ${(provider.minPrice ?? 0).toInt()}–${provider.maxPrice?.toInt() ?? '∞'}',
                ),
            ]),
          ),
        ),
        TextButton(
          onPressed: provider.clearFilters,
          child: const Text('Clear', style: TextStyle(color: AppColors.brandOrange, fontSize: 13)),
        ),
      ]),
    );
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'price_low': return 'Price ↑';
      case 'price_high': return 'Price ↓';
      case 'top_rated': return 'Top Rated';
      case 'best_selling': return 'Best Selling';
      default: return sort;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sort;
  late bool _inStock;
  late TextEditingController _minCtrl, _maxCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<SearchProvider>();
    _sort = p.sort;
    _inStock = p.inStockOnly;
    _minCtrl = TextEditingController(text: p.minPrice?.toInt().toString() ?? '');
    _maxCtrl = TextEditingController(text: p.maxPrice?.toInt().toString() ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _sort = 'newest';
                _inStock = false;
                _minCtrl.clear();
                _maxCtrl.clear();
              }),
              child: const Text('Reset', style: TextStyle(color: AppColors.brandOrange)),
            ),
          ]),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _sortChip('newest', 'Newest'),
            _sortChip('price_low', 'Price: Low → High'),
            _sortChip('price_high', 'Price: High → Low'),
            _sortChip('top_rated', 'Top Rated'),
            _sortChip('best_selling', 'Best Selling'),
          ]),
          const SizedBox(height: 18),
          const Text('Price Range (PKR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Min', isDense: true),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('–', style: TextStyle(fontSize: 16))),
            Expanded(
              child: TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Max', isDense: true),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _inStock,
            onChanged: (v) => setState(() => _inStock = v),
            title: const Text('In Stock Only', style: TextStyle(fontWeight: FontWeight.w500)),
            activeThumbColor: AppColors.brandOrange,
            activeTrackColor: AppColors.brandOrange.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<SearchProvider>().applyFilters(
                  newSort: _sort,
                  newInStock: _inStock,
                  newMinPrice: double.tryParse(_minCtrl.text.trim()),
                  newMaxPrice: double.tryParse(_maxCtrl.text.trim()),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final selected = _sort == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13)),
      selected: selected,
      onSelected: (_) => setState(() => _sort = value),
      selectedColor: AppColors.brandOrange,
      backgroundColor: AppColors.backgroundLight,
      side: BorderSide(color: selected ? AppColors.brandOrange : AppColors.borderLight),
    );
  }
}
