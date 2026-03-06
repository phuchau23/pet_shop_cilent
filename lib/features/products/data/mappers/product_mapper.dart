import '../models/product_response_dto.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_size.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/brand.dart';

class ProductMapper {
  static Product toEntity(ProductDto dto) {
    return Product(
      productId: dto.productId,
      name: dto.name,
      description: dto.description,
      price: dto.price, // Giá rẻ nhất từ API
      salePrice: null, // API không trả về salePrice
      stockQuantity: dto.stockQuantity, // Tổng tồn kho từ API
      category: Category(
        categoryId: dto.categoryId,
        name: dto.categoryName,
        description: null,
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      ),
      brand: Brand(
        brandId: dto.brandId,
        name: dto.brandName,
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      ),
      status: dto.isActive,
      viewCount: null,
      soldCount: null,
      petType: null,
      expiryDate: null,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
      images: dto.images.map((img) => img.imageUrl).toList(),
      productSizes: dto.productSizes.map((psDto) => ProductSize(
        productSizeId: psDto.productSizeId,
        size: psDto.size,
        price: psDto.price,
        stockQuantity: psDto.stockQuantity,
        isActive: psDto.isActive,
      )).toList(),
    );
  }

  static List<Product> toEntityList(List<ProductDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }
}
