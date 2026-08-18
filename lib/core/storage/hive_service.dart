import 'package:hive_flutter/hive_flutter.dart';
import '../../features/cart/models/cart_models.dart';

class HiveService {
  static const String _cartBoxName = 'cart_items';
  static final List<CartItem> _memoryFallback = [];

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CartItemAdapter());
    await Hive.openBox<CartItem>(_cartBoxName);
  }

  static bool get _isOpen {
    try {
      return Hive.isBoxOpen(_cartBoxName);
    } catch (_) {
      return false;
    }
  }

  static Box<CartItem>? get _cartBox {
    if (_isOpen) {
      try {
        return Hive.box<CartItem>(_cartBoxName);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<CartItem> getItems() {
    final box = _cartBox;
    if (box != null) {
      return box.values.toList();
    }
    return List<CartItem>.from(_memoryFallback);
  }

  static Future<void> saveItems(List<CartItem> items) async {
    final box = _cartBox;
    if (box != null) {
      await box.clear();
      for (final item in items) {
        await box.put(item.uuid, item);
      }
    } else {
      _memoryFallback.clear();
      _memoryFallback.addAll(items);
    }
  }

  static Future<void> clearItems() async {
    final box = _cartBox;
    if (box != null) {
      await box.clear();
    } else {
      _memoryFallback.clear();
    }
  }
}
