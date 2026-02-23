import 'package:dio/dio.dart';
import 'package:pet_shop/core/network/api_client.dart';
import 'package:pet_shop/core/network/api_response.dart';
import 'package:pet_shop/core/network/api_endpoints.dart';
import '../../models/product_response_dto.dart';

abstract class ProductRemoteDataSource {
  Future<ProductResponseDto> getProducts({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProductResponseDto> getProducts({
    required int pageNumber,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }

      final url = ApiEndpoints.buildUrlWithQuery(
        ApiEndpoints.getProducts,
        queryParams: queryParams,
      );

      print('📤 Fetching products: $url');

      final response = await apiClient.dio.get(url);

      print('📥 Products response status: ${response.statusCode}');

      final apiResponse = ApiResponse<ProductResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ProductResponseDto.fromJson(data as Map<String, dynamic>),
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
        throw Exception(errorData['message'] ?? 'Lỗi khi tải sản phẩm');
      } else {
        throw Exception('Không thể kết nối đến server');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }
}
