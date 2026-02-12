import 'category.dart';
import 'brand.dart';

class Product {
  final int productId;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final int stockQuantity;
  final Category category;
  final Brand brand;
  final bool status;
  final int? viewCount;
  final int? soldCount;
  final String? petType;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.stockQuantity,
    required this.category,
    required this.brand,
    required this.status,
    this.viewCount,
    this.soldCount,
    this.petType,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  bool get isOnSale => salePrice != null && salePrice! < price;
  double get finalPrice => salePrice ?? price;
  double get discountPercent {
    if (!isOnSale) return 0;
    return ((price - salePrice!) / price * 100).round().toDouble();
  }
}
