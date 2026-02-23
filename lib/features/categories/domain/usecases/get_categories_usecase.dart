import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase({required this.repository});

  Future<List<Category>> call({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    return await repository.getCategories(
      pageNumber: pageNumber,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }
}
