import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/cart_store.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../marketplace/search_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedTab = 0;
  final _pageController = PageController(initialPage: 0);

  void _onTabTapped(int idx) {
    if (idx == 2) {
      // Center browse button → push search screen
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
      return;
    }
    final realIdx = idx < 2 ? idx : idx - 1;
    setState(() => _selectedTab = idx);
    _pageController.jumpToPage(realIdx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(),
          SearchScreen(),
          CartScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _SoftStoreTabBar(
        selectedIndex: _selectedTab,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _SoftStoreTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _SoftStoreTabBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartStore>().count;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', selected: selectedIndex == 0, onTap: () => onTap(0)),
              _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search', selected: selectedIndex == 1, onTap: () => onTap(1)),
              // Center Browse Button
              _CenterBrowseButton(onTap: () => onTap(2)),
              _TabItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Cart',
                selected: selectedIndex == 3,
                badge: cartCount > 0 ? cartCount : null,
                onTap: () => onTap(3),
              ),
              _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', selected: selectedIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: selected ? AppColors.brandOrange : Colors.grey,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.brandOrange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterBrowseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterBrowseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandOrange, AppColors.brandAmber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x40FF6F00), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: const Center(
                child: Text('S', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
