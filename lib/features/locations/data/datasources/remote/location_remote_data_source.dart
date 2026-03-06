import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../models/province_dto.dart';
import '../../models/district_dto.dart';
import '../../models/ward_dto.dart';

abstract class LocationRemoteDataSource {
  Future<List<ProvinceDto>> getProvinces();
  Future<List<DistrictDto>> getDistricts(int provinceCode);
  Future<List<WardDto>> getWards(int districtCode);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final ApiClient apiClient;

  LocationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ProvinceDto>> getProvinces() async {
    try {
      print('📤 Fetching provinces: ${ApiClient.baseUrl}${ApiEndpoints.getProvinces}');

      final response = await apiClient.dio.get(ApiEndpoints.getProvinces);

      print('📥 Provinces response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<ProvinceDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List)
            .map((item) => ProvinceDto.fromJson(item as Map<String, dynamic>))
            .toList(),
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
        print('❌ Response: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối timeout. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy danh sách tỉnh/thành phố.');
    }
  }

  @override
  Future<List<DistrictDto>> getDistricts(int provinceCode) async {
    try {
      final url = ApiEndpoints.buildUrlWithQuery(
        ApiEndpoints.getDistricts,
        queryParams: {'province_code': provinceCode},
      );

      print('📤 Fetching districts: ${ApiClient.baseUrl}$url');

      final response = await apiClient.dio.get(url);

      print('📥 Districts response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<DistrictDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List)
            .map((item) => DistrictDto.fromJson(item as Map<String, dynamic>))
            .toList(),
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
        print('❌ Response: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối timeout. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy danh sách quận/huyện.');
    }
  }

  @override
  Future<List<WardDto>> getWards(int districtCode) async {
    try {
      final url = ApiEndpoints.buildUrlWithQuery(
        ApiEndpoints.getWards,
        queryParams: {'district_code': districtCode},
      );

      print('📤 Fetching wards: ${ApiClient.baseUrl}$url');

      final response = await apiClient.dio.get(url);

      print('📥 Wards response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<WardDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List)
            .map((item) => WardDto.fromJson(item as Map<String, dynamic>))
            .toList(),
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
        print('❌ Response: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối timeout. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy danh sách phường/xã.');
    }
  }
}
