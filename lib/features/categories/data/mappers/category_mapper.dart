import '../models/category_response_dto.dart';
import '../../domain/entities/category.dart';

class CategoryMapper {
  // Chuyển 1 CategoryDto thành Category entity
  static Category toEntity(CategoryDto dto) {
    return Category(
      categoryId: dto.categoryId,
      name: dto.name,
      description: dto.description,
      createdAt: DateTime.parse(dto.createdAt), // Parse string → DateTime
      updatedAt: DateTime.parse(dto.updatedAt),
    );
  }

  // Chuyển list CategoryDto thành list Category
  static List<Category> toEntityList(List<CategoryDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }
}
