import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase({required this.repository});

  Future<List<Product>> call({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    return await repository.getProducts(
      pageNumber: pageNumber,
      pageSize: pageSize,
      searchTerm: searchTerm,
    );
  }
}
