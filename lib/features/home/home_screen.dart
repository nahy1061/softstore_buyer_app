import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/loading_views.dart';
import '../../core/models/store.dart';
import '../../services/catalog_service.dart';
import '../marketplace/search_screen.dart';
import '../marketplace/product_detail_screen.dart';
import '../marketplace/store_detail_screen.dart';
import 'home_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider()..load(),
      child: const _HomeContent(),
    );
  }
}

// ---------------------------------------------------------------------------

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildAppBar(ctx)],
        body: RefreshIndicator(
          onRefresh: () => context.read<HomeProvider>().load(),
          color: AppColors.brandOrange,
          child: _buildBody(context, provider),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeProvider provider) {
    return switch (provider.state) {
      HomeLoadState.idle || HomeLoadState.loading => const LoadingView(),
      HomeLoadState.error => ErrorView(
          message: provider.error ?? 'Could not load home feed.',
          onRetry: () => context.read<HomeProvider>().load(),
        ),
      HomeLoadState.loaded => _HomeBody(data: provider.data!),
    };
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.brandOrange,
      foregroundColor: Colors.white,
      floating: true,
      snap: true,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('S', style: TextStyle(color: AppColors.brandOrange, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('SoftStore', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(children: [
                Icon(Icons.search, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Text('Search for products, brands...', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HomeBody extends StatelessWidget {
  final HomeResponse data;
  const _HomeBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HomeProvider>();
    return CustomScrollView(
      slivers: [
        // Category pills
        if (data.categories.isNotEmpty)
          SliverToBoxAdapter(child: _CategoryPills(categories: data.categories)),

        // Stores rail
        if (data.stores.isNotEmpty) ...[
          _SectionHeader(
            title: 'Browse Stores',
            onSeeAll: null,
          ),
          SliverToBoxAdapter(child: _StoresRail(stores: data.stores)),
        ],

        // Top Deals horizontal rail
        if (data.topDeals.isNotEmpty) ...[
          _SectionHeader(
            title: '🔥 Top Deals',
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen(initialTitle: 'Top Deals')),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalProductRail(
              products: data.topDeals,
              onWishlistToggle: (p) => provider.toggleWishlist(p.id),
            ),
          ),
        ],

        // Hero category rails
        for (final cat in data.heroCategories) ...[
          _SectionHeader(
            title: cat.name,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchScreen(initialCategorySlug: cat.slug, initialTitle: cat.name)),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalProductRail(products: cat.products),
          ),
        ],

        // Just For You grid
        if (data.featured.isNotEmpty) ...[
          const _SectionHeader(title: 'Just For You'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final p = data.featured[i];
                  return ProductCard(
                    product: p,
                    onTap: () => _openProduct(ctx, p),
                    onWishlistToggle: () => provider.toggleWishlist(p.id),
                  );
                },
                childCount: data.featured.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  void _openProduct(BuildContext context, Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: p.slug ?? '${p.id}')),
    );
  }
}

// ---------------------------------------------------------------------------

class _CategoryPills extends StatelessWidget {
  final List<MarketplaceCategory> categories;
  const _CategoryPills({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => SearchScreen(initialCategorySlug: cat.slug, initialTitle: cat.categoryName),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: Text(
                  cat.categoryName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HorizontalProductRail extends StatelessWidget {
  final List<Product> products;
  final void Function(Product)? onWishlistToggle;

  const _HorizontalProductRail({required this.products, this.onWishlistToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final p = products[i];
          return SizedBox(
            width: 155,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ProductCard(
                product: p,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: p.slug ?? '${p.id}')),
                ),
                onWishlistToggle: onWishlistToggle != null ? () => onWishlistToggle!(p) : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StoresRail extends StatelessWidget {
  final List<Store> stores;
  const _StoresRail({required this.stores});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stores.length,
        itemBuilder: (ctx, i) {
          final s = stores[i];
          final initial = s.businessName.isNotEmpty ? s.businessName[0].toUpperCase() : 'S';
          return GestureDetector(
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => StoreDetailScreen(slug: s.slug)),
            ),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brandOrange, AppColors.brandAmber],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      if (s.city != null)
                        Text(s.city!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
