import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:softstore_buyer_app/core/storage/hive_service.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/cart/models/cart_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cart Multi-Account Isolation & Guest Migration Tests', () {
    late Directory tempDir;
    late CartCubit cartCubit;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CartItemAdapter());
      }
      HiveService.setHiveInitializedForTesting(true);
    });

    tearDownAll(() async {
      HiveService.setHiveInitializedForTesting(false);
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    setUp(() async {
      cartCubit = CartCubit();
      await cartCubit.reloadForUser(null);
      await cartCubit.clearCart();
    });

    test('Guest items migrate cleanly to logged-in user, and separate users remain strictly isolated', () async {
      // 1. Guest adds an item
      const guestItem = CartItem(
        uuid: 'guest_prod_1',
        productId: 101,
        productName: 'Guest Item',
        quantity: 1,
        unitPriceSnapshot: 100.0,
      );
      await cartCubit.addItem(guestItem);
      expect(cartCubit.state.items.length, 1);
      expect(cartCubit.state.items.first.productName, 'Guest Item');

      // 2. User A logs in (e.g. alice@example.com) — Guest items migrate into User A
      await cartCubit.reloadForUser('alice@example.com');
      expect(cartCubit.state.items.length, 1,
          reason: 'Guest items migrate smoothly into User A on login so buyer does not lose cart');
      expect(cartCubit.state.items.first.productName, 'Guest Item');

      // 3. User A adds their own items
      const userAItem = CartItem(
        uuid: 'alice_prod_1',
        productId: 201,
        productName: 'Alice Laptop',
        quantity: 2,
        unitPriceSnapshot: 50000.0,
      );
      await cartCubit.addItem(userAItem);
      expect(cartCubit.state.items.length, 2);

      // 4. User B logs in (e.g. bob@example.com) — User B is completely isolated
      await cartCubit.reloadForUser('bob@example.com');
      expect(cartCubit.state.items, isEmpty,
          reason: 'User B starts with an empty cart, Alice items do not bleed into Bob');

      // 5. User B adds their own item
      const userBItem = CartItem(
        uuid: 'bob_prod_1',
        productId: 301,
        productName: 'Bob Headphones',
        quantity: 1,
        unitPriceSnapshot: 3000.0,
      );
      await cartCubit.addItem(userBItem);
      expect(cartCubit.state.items.length, 1);
      expect(cartCubit.state.items.first.productName, 'Bob Headphones');

      // 6. Switch back to User A — Alice\'s items must still be intact
      await cartCubit.reloadForUser('alice@example.com');
      expect(cartCubit.state.items.length, 2);
      expect(cartCubit.state.items.any((i) => i.productName == 'Alice Laptop'), isTrue);

      // 7. Clear User A\'s cart — verify it does not affect Bob
      await cartCubit.clearCart();
      expect(cartCubit.state.items, isEmpty);

      await cartCubit.reloadForUser('bob@example.com');
      expect(cartCubit.state.items.length, 1);
      expect(cartCubit.state.items.first.productName, 'Bob Headphones');
    });

    test('HiveService.sanitizeUserId safely handles emails, null, and empty IDs', () {
      expect(HiveService.sanitizeUserId(null), 'guest');
      expect(HiveService.sanitizeUserId(''), 'guest');
      expect(HiveService.sanitizeUserId('   '), 'guest');
      expect(HiveService.sanitizeUserId('alice@example.com'), 'alice_example_com');
      expect(HiveService.sanitizeUserId('User+123@domain.pk'), 'user_123_domain_pk');
    });
  });
}
