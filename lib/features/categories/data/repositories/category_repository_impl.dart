import '../../domain/repositories/category_repository.dart';
import '../../domain/entities/category.dart';
import '../datasources/remote/category_remote_data_source.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Category>> getCategories({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
      // 1. Gọi API qua Remote Data Source → nhận CategoryResponseDto
      final response = await remoteDataSource.getCategories(
        pageNumber: pageNumber,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );

      // 2. Map DTO → Entity và trả về
      return CategoryMapper.toEntityList(response.data);
    } catch (e) {
      rethrow; // Ném lại lỗi để UseCase xử lý
    }
  }
}
