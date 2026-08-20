import 'package:hive_flutter/hive_flutter.dart';
import '../../features/cart/models/cart_models.dart';

class HiveService {
  static const String _guestCartBoxName = 'cart_items_guest';
  static const String _cartBoxPrefix = 'cart_items_';
  static String _currentUserId = 'guest';
  static String _activeBoxName = _guestCartBoxName;
  static final Map<String, List<CartItem>> _memoryFallbacks = {};
  static bool _isHiveInitialized = false;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CartItemAdapter());
      }
      _isHiveInitialized = true;
      await _openBox(_guestCartBoxName);
    } catch (_) {
      // In-memory fallback will take over seamlessly
    }
  }

  static void setHiveInitializedForTesting([bool initialized = true]) {
    _isHiveInitialized = initialized;
  }

  static String sanitizeUserId(String? userId) {
    if (userId == null || userId.trim().isEmpty) return 'guest';
    final cleaned = userId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return cleaned.isEmpty ? 'guest' : cleaned;
  }

  static Future<void> setCartUser(String? userId) async {
    final sanitized = sanitizeUserId(userId);
    if (sanitized == _currentUserId) return;

    _currentUserId = sanitized;
    _activeBoxName = sanitized == 'guest'
        ? _guestCartBoxName
        : '$_cartBoxPrefix$sanitized';

    await _openBox(_activeBoxName);
  }

  static Future<void> ensureBoxOpen([String? boxName]) async {
    if (!_isHiveInitialized) return;
    final target = boxName ?? _activeBoxName;
    if (!_isBoxOpen(target)) {
      await _openBox(target);
    }
  }

  static Future<void> _openBox(String boxName) async {
    if (!_isHiveInitialized) return;
    try {
      if (!_isBoxOpen(boxName)) {
        try {
          await Hive.openBox<CartItem>(boxName);
        } catch (_) {
          try {
            await Hive.deleteBoxFromDisk(boxName);
            await Hive.openBox<CartItem>(boxName);
          } catch (_) {
            // In-memory fallback will take over
          }
        }
      }
    } catch (_) {
      // In-memory fallback will take over
    }
  }

  static Future<void> _closeBox(String boxName) async {
    try {
      if (_isBoxOpen(boxName)) {
        await Hive.box<CartItem>(boxName).close();
      }
    } catch (_) {}
  }

  static bool _isBoxOpen(String boxName) {
    try {
      return Hive.isBoxOpen(boxName);
    } catch (_) {
      return false;
    }
  }

  static Box<CartItem>? _getBox(String boxName) {
    if (_isBoxOpen(boxName)) {
      try {
        return Hive.box<CartItem>(boxName);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<CartItem> getItems() {
    final box = _getBox(_activeBoxName);
    if (box != null) {
      return box.values.toList();
    }
    return List<CartItem>.from(
      _memoryFallbacks[_activeBoxName] ?? [],
    );
  }

  static Future<void> saveItems(List<CartItem> items) async {
    final box = _getBox(_activeBoxName);
    if (box != null) {
      await box.clear();
      for (final item in items) {
        await box.put(item.uuid, item);
      }
    } else {
      _memoryFallbacks[_activeBoxName] = List<CartItem>.from(items);
    }
  }

  static Future<void> clearItems() async {
    final box = _getBox(_activeBoxName);
    if (box != null) {
      await box.clear();
    } else {
      _memoryFallbacks.remove(_activeBoxName);
    }
  }

  static Future<void> clearItemsForUser(String userId) async {
    final sanitized = sanitizeUserId(userId);
    final boxName =
        sanitized == 'guest' ? _guestCartBoxName : '$_cartBoxPrefix$sanitized';
    if (_isBoxOpen(boxName)) {
      try {
        await Hive.box<CartItem>(boxName).clear();
      } catch (_) {}
    } else {
      _memoryFallbacks.remove(boxName);
    }
  }
}
