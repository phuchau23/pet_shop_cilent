import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/brand.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../../../../core/database/isar_service.dart';
import 'package:isar/isar.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems(int userId);
  Future<void> addToCart(int userId, Product product, int quantity);
  Future<void> updateQuantity(int userId, int productId, int quantity);
  Future<void> removeFromCart(int userId, int productId);
  Future<void> clearCart(int userId);
  Future<int> getCartItemCount(int userId);
}

class CartRepositoryImpl implements CartRepository {
  @override
  Future<List<CartItem>> getCartItems(int userId) async {
    try {
      final isar = await IsarService.instance;

      // Tìm hoặc tạo cart cho user
      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) {
        cart = CartModel.create(userId: userId);
        await isar.writeTxn(() async {
          await isar.cartModels.put(cart!);
        });
      }

      // Load items
      await cart.items.load();
      final itemModels = cart.items.toList();

      // Convert to domain entities
      final cartItems = itemModels.map((item) {
        // Tạo Product entity từ CartItemModel
        final product = Product(
          productId: item.productId,
          name: item.productName,
          description: item.productDescription,
          price: item.productPrice,
          salePrice: item.productSalePrice,
          stockQuantity: item.productStockQuantity,
          category: Category(
            categoryId: item.categoryId,
            name: item.categoryName,
            description: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          brand: Brand(
            brandId: item.brandId,
            name: item.brandName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: item.productStatus,
          petType: item.productPetType,
          expiryDate: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          images: [item.productImageUrl],
        );

        return CartItem(product: product, quantity: item.quantity);
      }).toList();

      return cartItems;
    } catch (e) {
      print('❌ Error getting cart items: $e');
      rethrow;
    }
  }

  @override
  Future<void> addToCart(int userId, Product product, int quantity) async {
    try {
      final isar = await IsarService.instance;

      // Tìm hoặc tạo cart
      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) {
        cart = CartModel.create(userId: userId);
        await isar.writeTxn(() async {
          await isar.cartModels.put(cart!);
        });
      }

      // Kiểm tra sản phẩm đã có trong cart chưa
      await cart.items.load();
      final existingItem = cart.items.firstWhere(
        (item) => item.productId == product.productId,
        orElse: () => CartItemModel(),
      );

      await isar.writeTxn(() async {
        if (existingItem.id != Isar.autoIncrement) {
          // Update quantity nếu đã có
          existingItem.quantity += quantity;
          await isar.cartItemModels.put(existingItem);
        } else {
          // Tạo mới
          final cartItem = CartItemModel.create(
            productId: product.productId,
            productName: product.name,
            productDescription: product.description,
            productPrice: product.price,
            productSalePrice: product.salePrice,
            productStockQuantity: product.stockQuantity,
            categoryId: product.category.categoryId,
            categoryName: product.category.name,
            brandId: product.brand.brandId,
            brandName: product.brand.name,
            productStatus: product.status,
            productPetType: product.petType,
            productImageUrl: product.images.isNotEmpty
                ? product.images.first
                : '',
            quantity: quantity,
          );
          await isar.cartItemModels.put(cartItem);
          if (cart != null) {
            cart.items.add(cartItem);
            await cart.items.save();
          }
        }
      });

      print('✅ Added to cart: ${product.name} x$quantity');
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateQuantity(int userId, int productId, int quantity) async {
    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return;

      await cart.items.load();
      final item = cart.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => CartItemModel(),
      );

      if (item.id == Isar.autoIncrement) return;

      await isar.writeTxn(() async {
        if (quantity <= 0) {
          await isar.cartItemModels.delete(item.id);
          cart.items.remove(item);
          await cart.items.save();
        } else {
          item.quantity = quantity;
          await isar.cartItemModels.put(item);
        }
      });

      print('✅ Updated quantity: productId=$productId, quantity=$quantity');
    } catch (e) {
      print('❌ Error updating quantity: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(int userId, int productId) async {
    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return;

      await cart.items.load();
      final item = cart.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => CartItemModel(),
      );

      if (item.id == Isar.autoIncrement) return;

      await isar.writeTxn(() async {
        await isar.cartItemModels.delete(item.id);
        cart.items.remove(item);
        await cart.items.save();
      });

      print('✅ Removed from cart: productId=$productId');
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCart(int userId) async {
    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return;

      await cart.items.load();
      final itemIds = cart.items.map((item) => item.id).toList();

      await isar.writeTxn(() async {
        for (final id in itemIds) {
          await isar.cartItemModels.delete(id);
        }
        cart.items.clear();
        await cart.items.save();
      });

      print('✅ Cart cleared for user: $userId');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }

  @override
  Future<int> getCartItemCount(int userId) async {
    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return 0;

      await cart.items.load();
      final totalCount = cart.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      return totalCount;
    } catch (e) {
      print('❌ Error getting cart count: $e');
      return 0;
    }
  }
}
