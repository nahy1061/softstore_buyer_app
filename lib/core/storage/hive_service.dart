import 'package:hive_flutter/hive_flutter.dart';
import '../../features/cart/models/cart_models.dart';

class HiveService {
  static const String _cartBoxName = 'cart_items';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CartItemAdapter());
    await Hive.openBox<CartItem>(_cartBoxName);
  }

  static Box<CartItem> get _cartBox => Hive.box<CartItem>(_cartBoxName);

  static List<CartItem> getItems() {
    if (!Hive.isBoxOpen(_cartBoxName)) return [];
    return _cartBox.values.toList();
  }

  static Future<void> saveItems(List<CartItem> items) async {
    if (!Hive.isBoxOpen(_cartBoxName)) return;
    await _cartBox.clear();
    for (final item in items) {
      await _cartBox.put(item.uuid, item);
    }
  }

  static Future<void> clearItems() async {
    if (!Hive.isBoxOpen(_cartBoxName)) return;
    await _cartBox.clear();
  }
}
