import 'package:isar/isar.dart';

part 'cart_item_model.g.dart';

@collection
class CartItemModel {
  Id id = Isar.autoIncrement;

  // Product info (lưu trực tiếp vì không có relation với Product entity)
  late int productId;
  late String productName;
  late String productDescription;
  late double productPrice;
  double? productSalePrice;
  late int productStockQuantity;
  late int categoryId;
  late String categoryName;
  late int brandId;
  late String brandName;
  late bool productStatus;
  String? productPetType;
  late String productImageUrl; // Lưu ảnh đầu tiên

  // Cart item info
  late int quantity;
  late DateTime addedAt;

  CartItemModel();

  CartItemModel.create({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    this.productSalePrice,
    required this.productStockQuantity,
    required this.categoryId,
    required this.categoryName,
    required this.brandId,
    required this.brandName,
    required this.productStatus,
    this.productPetType,
    required this.productImageUrl,
    this.quantity = 1,
  }) : addedAt = DateTime.now();

  double get finalPrice => productSalePrice ?? productPrice;
  double get totalPrice => finalPrice * quantity;
}
