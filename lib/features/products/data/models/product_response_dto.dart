class ProductResponseDto {
  final List<ProductDto> data;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  ProductResponseDto({
    required this.data,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory ProductResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductResponseDto(
      data: (json['data'] as List)
          .map((item) => ProductDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      pageNumber: json['pageNumber'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}

class ProductDto {
  final int productId;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final int categoryId;
  final String categoryName;
  final int brandId;
  final String brandName;
  final bool isActive;
  final List<String> availableSizes;
  final List<ProductImageDto> images;
  final String createdAt;
  final String updatedAt;

  ProductDto({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.categoryId,
    required this.categoryName,
    required this.brandId,
    required this.brandName,
    required this.isActive,
    required this.availableSizes,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      productId: json['productId'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      brandId: json['brandId'] as int,
      brandName: json['brandName'] as String,
      isActive: json['isActive'] as bool,
      availableSizes: (json['availableSizes'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((item) => ProductImageDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class ProductImageDto {
  final int productImageId;
  final String imageUrl;
  final bool isPrimary;
  final int sortOrder;

  ProductImageDto({
    required this.productImageId,
    required this.imageUrl,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
      productImageId: json['productImageId'] as int,
      imageUrl: json['imageUrl'] as String,
      isPrimary: json['isPrimary'] as bool,
      sortOrder: json['sortOrder'] as int,
    );
  }
}
