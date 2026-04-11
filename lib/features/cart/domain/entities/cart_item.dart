import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_size.dart';

class CartItem {
  final Product product;
  final ProductSize productSize; // Size đã chọn
  int quantity;

  CartItem({
    required this.product,
    required this.productSize,
    this.quantity = 1,
  });

  double get totalPrice {
    final price = productSize.price.isNaN || productSize.price.isInfinite
        ? 0.0
        : productSize.price;
    final result = price * quantity;
    return result.isNaN || result.isInfinite ? 0.0 : result;
  }
  
  int get productSizeId => productSize.productSizeId;
  String get sizeName => productSize.size;
}
