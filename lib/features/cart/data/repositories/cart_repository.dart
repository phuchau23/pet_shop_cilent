import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_size.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/brand.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../../../../core/database/isar_service.dart';
import 'package:isar/isar.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems(int userId);
  Future<void> addToCart(int userId, Product product, ProductSize productSize, int quantity);
  Future<void> updateQuantity(int userId, int productId, int productSizeId, int quantity);
  Future<void> removeFromCart(int userId, int productId, int productSizeId);
  Future<void> clearCart(int userId);
  Future<int> getCartItemCount(int userId);
}

class CartRepositoryImpl implements CartRepository {
  @override
  Future<List<CartItem>> getCartItems(int userId) async {
    // Isar không hỗ trợ web, return empty list
    if (kIsWeb) {
      print('⚠️ Cart không hỗ trợ web. Chỉ hoạt động trên mobile (Android/iOS).');
      return [];
    }

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
        // Tạo ProductSize từ CartItemModel
        // Validate price để tránh NaN/Infinity
        final price = item.productSizePrice.isNaN || item.productSizePrice.isInfinite
            ? 0.0
            : item.productSizePrice;
        
        final productSize = ProductSize(
          productSizeId: item.productSizeId,
          size: item.productSizeName,
          price: price,
          stockQuantity: item.productSizeStockQuantity,
          isActive: true,
        );

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
          productSizes: [productSize], // Chỉ có size đã chọn
        );

        return CartItem(product: product, productSize: productSize, quantity: item.quantity);
      }).toList();

      return cartItems;
    } catch (e) {
      print('❌ Error getting cart items: $e');
      // Thay vì rethrow, return empty list để tránh loading xoay mãi
      // User sẽ thấy giỏ hàng trống thay vì loading vô tận
      return [];
    }
  }

  @override
  Future<void> addToCart(int userId, Product product, ProductSize productSize, int quantity) async {
    // Isar không hỗ trợ web
    if (kIsWeb) {
      print('⚠️ Cart không hỗ trợ web. Chỉ hoạt động trên mobile (Android/iOS).');
      return;
    }

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

      // Kiểm tra sản phẩm với cùng size đã có trong cart chưa
      await cart.items.load();
      CartItemModel? existingItem;
      try {
        existingItem = cart.items.firstWhere(
          (item) => item.productId == product.productId && item.productSizeId == productSize.productSizeId,
        );
      } catch (e) {
        // Không tìm thấy item, existingItem sẽ là null
        existingItem = null;
      }

      await isar.writeTxn(() async {
        if (existingItem != null && existingItem.id != Isar.autoIncrement) {
          // Update quantity nếu đã có cùng size
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
            productSizeId: productSize.productSizeId,
            productSizeName: productSize.size,
            productSizePrice: productSize.price,
            productSizeStockQuantity: productSize.stockQuantity,
            quantity: quantity,
          );
          await isar.cartItemModels.put(cartItem);
          if (cart != null) {
            cart.items.add(cartItem);
            await cart.items.save();
          }
        }
      });

      print('✅ Added to cart: ${product.name} (${productSize.size}) x$quantity');
    } catch (e) {
      print('❌ Error adding to cart: $e');
      final errorMsg = e.toString().toLowerCase();
      
      // Nếu lỗi là "Collection id is invalid", thử reset database và retry
      if (errorMsg.contains('collection id is invalid') || 
          errorMsg.contains('illegalarg')) {
        print('⚠️ Collection ID invalid detected in addToCart. Attempting to reset database...');
        try {
          await IsarService.resetDatabase();
          print('✅ Database reset. Retrying addToCart...');
          
          // Retry sau khi reset
          try {
            final isar = await IsarService.instance;
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
            
            await cart.items.load();
            CartItemModel? existingItemRetry;
            try {
              existingItemRetry = cart.items.firstWhere(
                (item) => item.productId == product.productId && item.productSizeId == productSize.productSizeId,
              );
            } catch (e) {
              existingItemRetry = null;
            }
            
            await isar.writeTxn(() async {
              if (existingItemRetry != null && existingItemRetry.id != Isar.autoIncrement) {
                existingItemRetry.quantity += quantity;
                await isar.cartItemModels.put(existingItemRetry);
              } else {
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
                  productImageUrl: product.images.isNotEmpty ? product.images.first : '',
                  productSizeId: productSize.productSizeId,
                  productSizeName: productSize.size,
                  productSizePrice: productSize.price,
                  productSizeStockQuantity: productSize.stockQuantity,
                  quantity: quantity,
                );
                await isar.cartItemModels.put(cartItem);
                cart!.items.add(cartItem);
                await cart.items.save();
              }
            });
            
            print('✅ Added to cart after reset: ${product.name} (${productSize.size}) x$quantity');
            return; // Success after reset
          } catch (retryError) {
            print('❌ Retry failed after reset: $retryError');
            // Silent fail để tránh loading xoay mãi
          }
        } catch (resetError) {
          print('❌ Failed to reset database: $resetError');
          // Silent fail để tránh loading xoay mãi
        }
      } else {
        // Các lỗi khác, không rethrow để tránh loading xoay mãi
        print('⚠️ addToCart failed but continuing: $e');
      }
    }
  }

  @override
  Future<void> updateQuantity(int userId, int productId, int productSizeId, int quantity) async {
    // Isar không hỗ trợ web
    if (kIsWeb) {
      print('⚠️ Cart không hỗ trợ web. Chỉ hoạt động trên mobile (Android/iOS).');
      return;
    }

    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return;

      await cart.items.load();
      CartItemModel? item;
      try {
        item = cart.items.firstWhere(
          (item) => item.productId == productId && item.productSizeId == productSizeId,
        );
      } catch (e) {
        return; // Item không tồn tại
      }

      final itemNonNull = item; // Non-null assertion
      if (itemNonNull.id == Isar.autoIncrement) return;

      await isar.writeTxn(() async {
        if (quantity <= 0) {
          await isar.cartItemModels.delete(itemNonNull.id);
          cart.items.remove(itemNonNull);
          await cart.items.save();
        } else {
          itemNonNull.quantity = quantity;
          await isar.cartItemModels.put(itemNonNull);
        }
      });

      print('✅ Updated quantity: productId=$productId, productSizeId=$productSizeId, quantity=$quantity');
    } catch (e) {
      print('❌ Error updating quantity: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(int userId, int productId, int productSizeId) async {
    // Isar không hỗ trợ web
    if (kIsWeb) {
      print('⚠️ Cart không hỗ trợ web. Chỉ hoạt động trên mobile (Android/iOS).');
      return;
    }

    try {
      final isar = await IsarService.instance;

      var cart = await isar.cartModels
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (cart == null) return;

      await cart.items.load();
      CartItemModel? item;
      try {
        item = cart.items.firstWhere(
          (item) => item.productId == productId && item.productSizeId == productSizeId,
        );
      } catch (e) {
        return; // Item không tồn tại
      }

      final itemNonNull = item; // Non-null assertion
      if (itemNonNull.id == Isar.autoIncrement) return;

      await isar.writeTxn(() async {
        await isar.cartItemModels.delete(itemNonNull.id);
        cart.items.remove(itemNonNull);
        await cart.items.save();
      });

      print('✅ Removed from cart: productId=$productId, productSizeId=$productSizeId');
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCart(int userId) async {
    // Isar không hỗ trợ web
    if (kIsWeb) {
      print('⚠️ Cart không hỗ trợ web. Chỉ hoạt động trên mobile (Android/iOS).');
      return;
    }

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
      // Không rethrow để tránh lỗi khi logout
      // Silent fail - cart sẽ được xóa khi database reset
    }
  }

  @override
  Future<int> getCartItemCount(int userId) async {
    // Isar không hỗ trợ web
    if (kIsWeb) {
      return 0;
    }

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
