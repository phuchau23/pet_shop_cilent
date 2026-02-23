import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  });
}
