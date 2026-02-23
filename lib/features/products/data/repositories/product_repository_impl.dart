import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../datasources/remote/product_remote_data_source.dart';
import '../mappers/product_mapper.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Product>> getProducts({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
      final response = await remoteDataSource.getProducts(
        pageNumber: pageNumber,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );
      return ProductMapper.toEntityList(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
