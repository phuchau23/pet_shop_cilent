import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../data/repositories/cart_repository.dart';
import '../../../../core/storage/user_storage.dart';

// Cart Repository Provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl();
});

// User ID Provider
final userIdProvider = FutureProvider<int?>((ref) async {
  return await UserStorage.getUserId();
});

// Cart Items Provider
final cartItemsProvider = FutureProvider.family<List<CartItem>, int>((ref, userId) async {
  final repository = ref.watch(cartRepositoryProvider);
  return await repository.getCartItems(userId);
});

// Cart Item Count Provider
final cartItemCountProvider = FutureProvider.family<int, int>((ref, userId) async {
  final repository = ref.watch(cartRepositoryProvider);
  return await repository.getCartItemCount(userId);
});

// Cart Notifier
class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartRepository _repository;
  final int _userId;

  CartNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final items = await _repository.getCartItems(_userId);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart(Product product, int quantity) async {
    try {
      await _repository.addToCart(_userId, product, quantity);
      await _loadCart();
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      await _repository.updateQuantity(_userId, productId, quantity);
      await _loadCart();
    } catch (e) {
      print('❌ Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      await _repository.removeFromCart(_userId, productId);
      await _loadCart();
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _repository.clearCart(_userId);
      await _loadCart();
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }
}

// Cart Notifier Provider
final cartNotifierProvider =
    StateNotifierProvider.family<CartNotifier, AsyncValue<List<CartItem>>, int>(
  (ref, userId) {
    final repository = ref.watch(cartRepositoryProvider);
    return CartNotifier(repository, userId);
  },
);

// Cart Count Notifier
class CartCountNotifier extends StateNotifier<AsyncValue<int>> {
  final CartRepository _repository;
  final int _userId;

  CartCountNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final count = await _repository.getCartItemCount(_userId);
      state = AsyncValue.data(count);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadCount();
  }
}

// Cart Count Notifier Provider
final cartCountNotifierProvider =
    StateNotifierProvider.family<CartCountNotifier, AsyncValue<int>, int>(
  (ref, userId) {
    final repository = ref.watch(cartRepositoryProvider);
    return CartCountNotifier(repository, userId);
  },
);
