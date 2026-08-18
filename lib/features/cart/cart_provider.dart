// CartStore is itself a ChangeNotifier that manages cart state and persistence.
// This file re-exports it as the canonical cart provider.
//
// Register once at the root of the widget tree:
//
//   ChangeNotifierProvider.value(value: CartStore.instance, child: ...)
//
// Then access via:
//   context.watch<CartStore>()     // rebuild on changes
//   context.read<CartStore>()      // single read / mutations
//
export '../../core/storage/cart_store.dart' show CartStore;
