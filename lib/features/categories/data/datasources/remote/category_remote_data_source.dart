import 'package:dio/dio.dart';
import 'package:pet_shop/core/network/api_client.dart';
import 'package:pet_shop/core/network/api_response.dart';
import 'package:pet_shop/core/network/api_endpoints.dart';
import '../../models/category_response_dto.dart';

abstract class CategoryRemoteDataSource {
  Future<CategoryResponseDto> getCategories({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient apiClient;

  CategoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CategoryResponseDto> getCategories({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
      // Build query params
      final queryParams = {'PageNumber': pageNumber, 'PageSize': pageSize};

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = int.parse(searchTerm);
      }

      // Build URL: /api/categories?PageNumber=1&PageSize=10
      final url = ApiEndpoints.buildUrlWithQuery(
        ApiEndpoints.getCategories,
        queryParams: queryParams,
      );

      print('📤 Fetching categories: $url');

      // Gọi API GET (token tự động được thêm bởi AuthInterceptor)
      final response = await apiClient.dio.get(url);

      print('📥 Categories response status: ${response.statusCode}');

      // Parse response thành CategoryResponseDto
      final apiResponse = ApiResponse<CategoryResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CategoryResponseDto.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Error message: ${e.message}');

      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Lỗi khi tải danh mục');
      } else {
        throw Exception('Không thể kết nối đến server');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }
}
