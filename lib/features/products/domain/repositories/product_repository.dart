import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  });
}
