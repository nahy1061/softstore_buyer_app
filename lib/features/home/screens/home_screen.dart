import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../catalog/models/catalog_models.dart';
import '../../catalog/repository/catalog_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CatalogRepository _catalogRepo = CatalogRepository.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _bannerPageCtrl = PageController();

  bool _isLoading = false;
  String? _error;
  HomepageData? _homepageData;
  SearchResult? _searchResult;
  String _selectedCategory = 'All';
  bool _isSearching = false;
  int _activeBannerIndex = 0;
  Timer? _bannerTimer;

  // Real SoftStore.pk product catalog items for instant zero-latency loading
  static const List<Product> _defaultProducts = [
    Product(
      id: 39,
      name: "Vichy Normaderm Phytosolution Intensive Purifying Gel | Deep Cleansing for Oily & Acne-Prone Skin",
      slug: "vichy-normaderm-phytosolution-intensive-purifying-gel-deep-cleansing-for-oily-acne-prone-skin",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260814_202604_3b05d6990315064c.png",
      displayPrice: 5000.0,
    ),
    Product(
      id: 38,
      name: "L'Oréal Paris Age Perfect Golden Age Rosé Oil-Serum | Anti-Sagging & Revitalizing Facial Care",
      slug: "l-oreal-paris-age-perfect-golden-age-rose-oil-serum-anti-sagging-revitalizing-facial-care",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260814_200955_764d93333c0d09dd.png",
      displayPrice: 3500.0,
    ),
    Product(
      id: 37,
      name: "L'Oréal Paris Revitalift 1.5% Pure Hyaluronic Acid Face Serum - 30ml (Fragrance-Free)",
      slug: "l-oreal-paris-revitalift-1-5-pure-hyaluronic-acid-face-serum-30ml-fragrance-free",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260814_200339_0ab8fcf9f7ed6816.png",
      displayPrice: 4000.0,
    ),
    Product(
      id: 36,
      name: "L'Oréal Revitalift Derm Intensives 10% Glycolic Acid Face Serum - Fragrance-Free, 1 Fl Oz",
      slug: "l-oreal-revitalift-derm-intensives-10-glycolic-acid-face-serum-fragrance-free-1-fl-oz",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260814_193343_a144d0cf269ae399.png",
      displayPrice: 4500.0,
    ),
    Product(
      id: 42,
      name: "Men’s Black Leather Strap Sandals available sizes 40,42,44 and 45",
      slug: "men-s-black-leather-strap-sandals-available-sizes-40-42-44-and-45",
      imageUrl: "https://softstore.pk/media/tenants/21/products/20260815_160154_f9539afd33df074f.png",
      displayPrice: 3300.0,
    ),
    Product(
      id: 41,
      name: "Men’s Brown Adjustable Comfort Sandals sizes available 6,7,8,10,12",
      slug: "men-s-brown-adjustable-comfort-sandals-sizes-available-6-7-8-10-12",
      imageUrl: "https://softstore.pk/media/tenants/21/products/20260815_153243_756ef6c69ccdc2ae.jpg",
      displayPrice: 4000.0,
    ),
    Product(
      id: 49,
      name: "Le Falconé Garcia Pour Homme Perfumed Body Spray-200ml",
      slug: "le-falcone-garcia-pour-homme-perfumed-body-spray-200ml",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260815_200056_3c0d677144bb312a.jpg",
      displayPrice: 1300.0,
    ),
    Product(
      id: 48,
      name: "Mirada #HASHTAG Pour Homme Perfumed Body Spray-200ml",
      slug: "mirada-hashtag-pour-homme-perfumed-body-spray-200ml",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260815_195614_a38a2533db02a825.jpg",
      displayPrice: 1300.0,
    ),
    Product(
      id: 47,
      name: "Mirada Enigma Pour Femme Perfumed Body Spray-200ml",
      slug: "mirada-enigma-pour-femme-perfumed-body-spray-200ml",
      imageUrl: "https://softstore.pk/media/tenants/25/products/20260815_194015_37bb1e586a41ece3.jpg",
      displayPrice: 1300.0,
    ),
    Product(
      id: 30,
      name: "Premium Wireless HeadPhone",
      slug: "premium-wireless-headphone",
      imageUrl: "https://softstore.pk/media/tenants/20/products/20260812_130952_f7d13581da439f2f.png",
      displayPrice: 5000.0,
    ),
    Product(
      id: 29,
      name: "Google Pixel Adopter ",
      slug: "google-pixel-adopter",
      imageUrl: "https://softstore.pk/media/tenants/20/products/20260811_142028_821f9f0be3df2b26.jpg",
      displayPrice: 2200.0,
    ),
    Product(
      id: 13,
      name: "Iphone 15 Pro Cover",
      slug: "iphone-15-pro-cover",
      imageUrl: "https://softstore.pk/media/tenants/8/products/20260807_033001_d49db28ce6a286a3.png",
      displayPrice: 1000.0,
    ),
    Product(
      id: 1,
      name: "Coca Cola 1.5L Bottle",
      slug: "coca-cola-1-5l-bottle",
      imageUrl: "https://softstore.pk/media/tenants/1/products/20260806_060112_f57034ddc476b4b1.jpg",
      displayPrice: 200.0,
    ),
    Product(
      id: 16,
      name: "46.5-Inch Rectangular Coffee Table with Marble-Effect Top and Gold Frame, 2-Tier Storage for Living Room",
      slug: "46-5-inch-rectangular-coffee-table-with-marble-effect-top-and-gold-frame-2-tier-storage-for-living-room",
      imageUrl: "https://softstore.pk/media/tenants/10/products/20260808_123433_5937eb3a38c27bb9.webp",
      displayPrice: 17999.0,
    ),
    Product(
      id: 19,
      name: "Freestanding Closet Organizer, Garment Rack with 6 Shelves",
      slug: "freestanding-closet-organizer-garment-rack-with-6-shelves",
      imageUrl: "https://softstore.pk/media/tenants/10/products/20260808_133201_3a6a61f18094a092.webp",
      displayPrice: 35000.0,
    ),
    Product(
      id: 34,
      name: "Premium Pure Shilajit – Natural Mountain Resin | Authentic Quality| packet per tola",
      slug: "shilajit-packet-per-tola",
      imageUrl: "https://softstore.pk/media/tenants/9/products/20260812_154415_ff4715f0ddd99168.jpg",
      displayPrice: 800.0,
    ),
    Product(
      id: 33,
      name: "Gilgit Kilao Dry Fruit – 100% Natural & Premium Quality",
      slug: "kilao",
      imageUrl: "https://softstore.pk/media/tenants/9/products/20260812_152545_f616a176a12652e1.jpg",
      displayPrice: 4000.0,
    ),
    Product(
      id: 32,
      name: "Gilgit Premium Dry Walnuts – Fresh & Natural | Rs. 850 per KG",
      slug: "walnut",
      imageUrl: "https://softstore.pk/media/tenants/9/products/20260812_151635_3d2b74024828b759.jpg",
      displayPrice: 1150.0,
    ),
    Product(
      id: 31,
      name: "Gilgit Premium Almonds (Badam) – Fresh & Natural Dry Fruit",
      slug: "almond",
      imageUrl: "https://softstore.pk/media/tenants/9/products/20260812_150713_9cf4be37868bc7c0.jpg",
      displayPrice: 1400.0,
    ),
  ];

  // Category definitions matching softstore marketplace
  static const List<Map<String, String>> _categories = [
    {
      'name': 'General Store Items',
      'displayName': 'General\nStore Items',
      'slug': 'general',
      'thumbnail': 'https://softstore.pk/media/tenants/21/products/20260815_160154_f9539afd33df074f.png',
    },
    {
      'name': 'Personal Care & Hygiene',
      'displayName': 'Personal\nCare & Hy...',
      'slug': 'personal-care',
      'thumbnail': 'https://softstore.pk/media/tenants/25/products/20260815_200056_3c0d677144bb312a.jpg',
    },
    {
      'name': 'Beverages & Cold Drinks',
      'displayName': 'Beverages\n& Cold Dri...',
      'slug': 'beverages',
      'thumbnail': 'https://softstore.pk/media/tenants/1/products/20260806_060112_f57034ddc476b4b1.jpg',
    },
    {
      'name': 'Furniture',
      'displayName': 'Furniture',
      'slug': 'furniture',
      'thumbnail': 'https://softstore.pk/media/tenants/10/products/20260808_123433_5937eb3a38c27bb9.webp',
    },
    {
      'name': 'Mobile Accessories',
      'displayName': 'Mobile\nAccessories',
      'slug': 'mobile-accessories',
      'thumbnail': 'https://softstore.pk/media/tenants/20/products/20260812_130952_f7d13581da439f2f.png',
    },
  ];

  // Dynamic session map pre-initialized with live catalog products
  late final Map<String, List<Product>> _categoryProductsMap;

  @override
  void initState() {
    super.initState();
    _categoryProductsMap = {
      'general': [
        _defaultProducts[0], // Vichy Normaderm
        _defaultProducts[1], // L'Oreal Age Perfect
        _defaultProducts[2], // L'Oreal Revitalift Hyaluronic
        _defaultProducts[3], // L'Oreal Revitalift Glycolic
        _defaultProducts[4], // Men's Black Sandals
        _defaultProducts[5], // Men's Brown Sandals
        _defaultProducts[13], // 46.5-Inch Coffee Table
        _defaultProducts[14], // Closet Organizer
        _defaultProducts[15], // Shilajit
        _defaultProducts[16], // Kilao
        _defaultProducts[17], // Walnuts
        _defaultProducts[18], // Almonds
      ],
      'personal-care': [
        _defaultProducts[6], // Le Falcone Garcia Spray
        _defaultProducts[7], // Mirada #HASHTAG Spray
        _defaultProducts[8], // Mirada Enigma Spray
      ],
      'beverages': [
        _defaultProducts[12], // Coca Cola 1.5L
      ],
      'furniture': [
        _defaultProducts[13], // 46.5-Inch Rectangular Coffee Table
        _defaultProducts[14], // Closet Organizer
      ],
      'mobile-accessories': [
        _defaultProducts[9], // Wireless HeadPhone
        _defaultProducts[10], // Pixel Adopter
        _defaultProducts[11], // Iphone 15 Pro Cover
      ],
    };

    _loadData();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isSearching) return;
      final totalBanners = 5;
      final nextIndex = (_activeBannerIndex + 1) % totalBanners;
      if (_bannerPageCtrl.hasClients) {
        _bannerPageCtrl.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final data = await _catalogRepo.getHomepage();
      if (!mounted) return;
      setState(() {
        _homepageData = data;
        _error = null;
      });

      _loadCategoryRails();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is Failure ? e.message : 'Live session active';
      });
    }
  }

  Future<void> _loadCategoryRails() async {
    for (final cat in _categories) {
      final slug = cat['slug']!;
      try {
        final res = await _catalogRepo.searchProducts(
          query: '',
          category: slug,
        );
        if (mounted && res.products.isNotEmpty) {
          setState(() {
            _categoryProductsMap[slug] = res.products;
          });
        }
      } catch (_) {
        // Keeps the instant catalog on individual category failure
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty && _selectedCategory == 'All') {
      setState(() {
        _isSearching = false;
        _searchResult = null;
      });
      return;
    }

    final slug = _selectedCategory == 'All' ? null : _getSlugForCategory(_selectedCategory);

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final res = await _catalogRepo.searchProducts(
        query: query.trim(),
        category: slug,
      );
      if (!mounted) return;
      setState(() {
        _searchResult = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Filter locally from category or full catalog
      final baseList = slug != null && _categoryProductsMap.containsKey(slug)
          ? _categoryProductsMap[slug]!
          : _defaultProducts;
      final filtered = query.trim().isEmpty
          ? baseList
          : baseList.where((p) =>
              p.name.toLowerCase().contains(query.trim().toLowerCase())).toList();
      setState(() {
        _searchResult = SearchResult(products: filtered, totalCount: filtered.length);
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCategory(String catName) async {
    if (_selectedCategory == catName) {
      setState(() {
        _selectedCategory = 'All';
        _isSearching = _searchCtrl.text.trim().isNotEmpty;
        if (!_isSearching) _searchResult = null;
      });
      if (_isSearching) {
        _performSearch(_searchCtrl.text.trim());
      }
      return;
    }

    setState(() {
      _selectedCategory = catName;
    });

    if (catName == 'All' && _searchCtrl.text.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResult = null;
      });
      return;
    }

    final slug = _getSlugForCategory(catName);

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final res = await _catalogRepo.searchProducts(
        query: _searchCtrl.text.trim(),
        category: slug == 'all' ? null : slug,
      );
      if (!mounted) return;
      setState(() {
        _searchResult = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final baseList = _categoryProductsMap[slug] ?? _defaultProducts;
      final filtered = _searchCtrl.text.trim().isEmpty
          ? baseList
          : baseList.where((p) =>
              p.name.toLowerCase().contains(_searchCtrl.text.trim().toLowerCase())).toList();
      setState(() {
        _searchResult = SearchResult(products: filtered, totalCount: filtered.length);
        _isLoading = false;
      });
    }
  }

  String _getSlugForCategory(String catName) {
    final lower = catName.trim().toLowerCase();
    for (final cat in _categories) {
      if (cat['name']!.toLowerCase() == lower || cat['slug']!.toLowerCase() == lower) {
        return cat['slug']!;
      }
    }
    return catName.trim().toLowerCase();
  }

  List<Product> _getProductsForCategory(String slug) {
    if (_categoryProductsMap.containsKey(slug) && _categoryProductsMap[slug]!.isNotEmpty) {
      return _categoryProductsMap[slug]!;
    }
    return _defaultProducts;
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> allProducts;
    if (_homepageData != null && _homepageData!.featuredProducts.isNotEmpty) {
      allProducts = _homepageData!.featuredProducts;
    } else {
      allProducts = _defaultProducts;
    }

    final List<Product> searchOrFilterProducts;
    if (_isSearching && _searchResult != null) {
      searchOrFilterProducts = _searchResult!.products;
    } else {
      searchOrFilterProducts = [];
    }

    // Hero banner items: Vichy first, followed by live featured items
    final bannerProducts = <Product>[];
    final vichy = allProducts.firstWhere(
      (p) => p.name.toLowerCase().contains('vichy'),
      orElse: () => _defaultProducts.first,
    );
    bannerProducts.add(vichy);

    for (final p in allProducts) {
      if (bannerProducts.length >= 5) break;
      if (!bannerProducts.any((b) => b.slug == p.slug)) {
        bannerProducts.add(p);
      }
    }
    while (bannerProducts.length < 5 && _defaultProducts.length >= 5) {
      for (final dp in _defaultProducts) {
        if (bannerProducts.length >= 5) break;
        if (!bannerProducts.any((b) => b.slug == dp.slug)) {
          bannerProducts.add(dp);
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 14,
        title: _buildLogoWidget(),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF1F2937),
                      size: 26,
                    ),
                    onPressed: () => context.go(AppRoutes.cart),
                  ),
                  if (cartState.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6A00),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cartState.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF1F2937),
              size: 27,
            ),
            onPressed: () => context.go(AppRoutes.support),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF6A00),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Search Bar & Orange Button ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: _performSearch,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          hintText: 'Search products, brands...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          suffixIcon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _performSearch(_searchCtrl.text),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6A00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Trust Badges Row ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(child: _buildTrustBadge(Icons.verified_user_outlined, 'Safe Payment')),
                    _buildBadgeDivider(),
                    Flexible(child: _buildTrustBadge(Icons.local_shipping_outlined, 'Fast Delivery')),
                    _buildBadgeDivider(),
                    Flexible(child: _buildTrustBadge(Icons.replay, 'Free Return')),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── 3. Search Results Grid (if active) ─────────────────────────
              if (_isSearching) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Results for "${_searchCtrl.text.isNotEmpty ? _searchCtrl.text : _selectedCategory}"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _selectedCategory = 'All';
                            _searchCtrl.clear();
                            _searchResult = null;
                          });
                        },
                        child: const Text(
                          'Clear Filter',
                          style: TextStyle(color: Color(0xFFFF6A00)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
                    ),
                  )
                else if (searchOrFilterProducts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text(
                      'No matching products found.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: searchOrFilterProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final product = searchOrFilterProducts[index];
                        return _buildProductCard(context, product);
                      },
                    ),
                  ),
              ] else ...[
                // ── 4. Hero Banner Slider ────────────────────────────────────
                SizedBox(
                  height: 210,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _bannerPageCtrl,
                        itemCount: bannerProducts.length,
                        onPageChanged: (idx) {
                          setState(() {
                            _activeBannerIndex = idx;
                          });
                        },
                        itemBuilder: (context, index) {
                          final product = bannerProducts[index];
                          return _buildHeroBannerItem(context, product);
                        },
                      ),
                      // Centered Pagination Dots at Bottom
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            bannerProducts.length,
                            (i) {
                              final isActive = i == (_activeBannerIndex % bannerProducts.length);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                width: isActive ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFFF6A00)
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── 5. Circular Category Avatars Row ─────────────────────────
                SizedBox(
                  height: 108,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final catName = cat['name']!;
                      final displayName = cat['displayName']!;
                      final isSelected = catName == _selectedCategory;
                      final imageUrl = cat['thumbnail'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _selectCategory(catName),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFFF6A00).withValues(alpha: 0.1)
                                      : const Color(0xFFF3F4F6),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF6A00)
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildFallbackCategoryIcon(catName),
                                        )
                                      : _buildFallbackCategoryIcon(catName),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFFF6A00)
                                        : const Color(0xFF1F2937),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ── 6. Categorized Horizontal Product Rails ──────────────────
                // Rail 1: General Store Items
                _buildProductRailSection(
                  title: 'General Store Items',
                  categorySlug: 'general',
                  products: _getProductsForCategory('general'),
                ),

                const SizedBox(height: 18),

                // Rail 2: Personal Care & Hygiene
                _buildProductRailSection(
                  title: 'Personal Care & Hygiene',
                  categorySlug: 'personal-care',
                  products: _getProductsForCategory('personal-care'),
                ),

                const SizedBox(height: 18),

                // Rail 3: Mobile Accessories
                _buildProductRailSection(
                  title: 'Mobile Accessories',
                  categorySlug: 'mobile-accessories',
                  products: _getProductsForCategory('mobile-accessories'),
                ),

                const SizedBox(height: 18),

                // Rail 4: Beverages & Cold Drinks
                _buildProductRailSection(
                  title: 'Beverages & Cold Drinks',
                  categorySlug: 'beverages',
                  products: _getProductsForCategory('beverages'),
                ),

                const SizedBox(height: 18),

                // Rail 5: Furniture
                _buildProductRailSection(
                  title: 'Furniture',
                  categorySlug: 'furniture',
                  products: _getProductsForCategory('furniture'),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildLogoWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo.jpeg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFFF6A00),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'SoftStore',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextSpan(
                    text: '.pk',
                    style: TextStyle(
                      color: Color(0xFFFF6A00),
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'BUYER MARKETPLACE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBannerItem(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push(
        '/product/${product.slug}',
        extra: {
          'id': product.id,
          'name': product.name,
          'price': product.displayPrice.toInt(),
          'imageUrl': product.imageUrl,
        },
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE5E7EB),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF374151),
                  ),
                ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Content Row
              Positioned(
                left: 14,
                right: 14,
                bottom: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${product.displayPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              color: Color(0xFFFF6A00),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFFF6A00),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRailSection({
    required String title,
    required List<Product> products,
    String? categorySlug,
  }) {
    final displayList = products.isNotEmpty ? products : _defaultProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 19,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (categorySlug != null && categorySlug.isNotEmpty) {
                    context.push(
                      '/category-products/$categorySlug',
                      extra: {'name': title},
                    );
                  } else {
                    context.go(AppRoutes.categories);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFFFF6A00),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFFFF6A00),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal Card Rail
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final product = displayList[index];
              return Container(
                width: 152,
                margin: const EdgeInsets.only(right: 12),
                child: _buildProductCard(context, product),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push(
        '/product/${product.slug}',
        extra: {
          'id': product.id,
          'name': product.name,
          'price': product.displayPrice.toInt(),
          'imageUrl': product.imageUrl,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Container
            SizedBox(
              height: 136,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
            // Title & Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.displayPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF6A00), size: 14),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeDivider() {
    return Container(
      height: 14,
      width: 1,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildFallbackCategoryIcon(String catName) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          _getCategoryIcon(catName),
          color: const Color(0xFFFF6A00),
          size: 26,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String catName) {
    final lower = catName.toLowerCase();
    if (lower.contains('personal') || lower.contains('care') || lower.contains('hygiene')) {
      return Icons.sanitizer_outlined;
    }
    if (lower.contains('mobile') || lower.contains('access')) {
      return Icons.headphones_outlined;
    }
    if (lower.contains('beverage') || lower.contains('drink')) {
      return Icons.local_drink_outlined;
    }
    if (lower.contains('furniture') || lower.contains('home')) {
      return Icons.chair_outlined;
    }
    if (lower.contains('fashion') || lower.contains('clothing')) {
      return Icons.checkroom_outlined;
    }
    if (lower.contains('dairy') || lower.contains('egg')) {
      return Icons.egg_outlined;
    }
    if (lower.contains('fruit') || lower.contains('produce') || lower.contains('organic')) {
      return Icons.spa_outlined;
    }
    return Icons.grid_view_outlined;
  }
}
