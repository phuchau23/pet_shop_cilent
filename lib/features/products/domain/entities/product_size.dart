class ProductSize {
  final int productSizeId;
  final String size;
  final double price;
  final int stockQuantity;
  final bool isActive;

  ProductSize({
    required this.productSizeId,
    required this.size,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
  });

  bool get isInStock => stockQuantity > 0;
}
