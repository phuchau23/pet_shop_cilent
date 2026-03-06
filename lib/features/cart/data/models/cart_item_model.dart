import 'package:isar/isar.dart';

part 'cart_item_model.g.dart';

@collection
class CartItemModel {
  Id id = Isar.autoIncrement;

  // Product info (lưu trực tiếp vì không có relation với Product entity)
  int productId = 0;
  String productName = '';
  String productDescription = '';
  double productPrice = 0.0;
  double? productSalePrice;
  int productStockQuantity = 0;
  int categoryId = 0;
  String categoryName = '';
  int brandId = 0;
  String brandName = '';
  bool productStatus = true;
  String? productPetType;
  String productImageUrl = ''; // Lưu ảnh đầu tiên

  // ProductSize info
  int productSizeId = 0;
  String productSizeName = ''; // "1kg", "5kg", etc.
  double productSizePrice = 0.0; // Giá của size đã chọn
  int productSizeStockQuantity = 0; // Tồn kho của size đã chọn

  // Cart item info
  int quantity = 1;
  DateTime addedAt = DateTime.now();

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
    required this.productSizeId,
    required this.productSizeName,
    required this.productSizePrice,
    required this.productSizeStockQuantity,
    this.quantity = 1,
  }) : addedAt = DateTime.now();

  double get finalPrice => productSalePrice ?? productSizePrice; // Dùng giá của size đã chọn
  double get totalPrice => productSizePrice * quantity; // Dùng giá của size đã chọn
}
