import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/session_store.dart';
import '../../services/auth_service.dart';
import '../auth/auth_flow_view.dart';
import 'profile_edit_screen.dart';
import 'addresses_screen.dart';
import 'wishlist_screen.dart';
import '../orders/orders_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionStore>(builder: (context, session, _) {
      if (!session.isSignedIn) return _guestView(context);
      return _signedInView(context, session);
    });
  }

  Widget _guestView(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundLight,
    appBar: AppBar(title: const Text('Profile')),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
        child: const Icon(Icons.person_outline, size: 44, color: Colors.grey),
      ),
      const SizedBox(height: 16),
      const Text('You are not signed in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Sign in to access your profile, orders, and more.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => AuthFlowView.showAuthSheet(context, contextMessage: 'Sign in to access your account'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandOrange, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
        child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ])),
  );

  Widget _signedInView(BuildContext context, SessionStore session) {
    final buyer = session.buyer!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
        ],
      ),
      body: ListView(children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.brandOrange,
              child: Text(buyer.initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(buyer.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(buyer.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (buyer.phone != null && buyer.phone!.isNotEmpty) Text(buyer.phone!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        // Menu
        _section('Shopping'),
        _tile(context, Icons.shopping_bag_outlined, 'My Orders', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
        _tile(context, Icons.favorite_outline, 'Wishlist', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
        _tile(context, Icons.location_on_outlined, 'Addresses', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
        const SizedBox(height: 12),
        _section('Support'),
        _tile(context, Icons.support_agent_outlined, 'Support', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
        const SizedBox(height: 12),
        _section('Account'),
        _tile(context, Icons.edit_outlined, 'Edit Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
        _tile(context, Icons.logout, 'Sign Out', () => _signOut(context, session), color: AppColors.danger),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) => ListTile(
    tileColor: Colors.white,
    leading: Icon(icon, color: color ?? AppColors.brandOrange),
    title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );

  void _signOut(BuildContext context, SessionStore session) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await AuthService().logout();
            await session.signOut();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}
