import 'package:dio/dio.dart';
import 'package:pet_shop/core/network/api_client.dart';
import 'package:pet_shop/core/network/api_endpoints.dart';
import 'package:pet_shop/core/network/api_response.dart';
import '../../models/voucher_dto.dart';

abstract class VoucherRemoteDataSource {
  Future<List<VoucherDto>> getVouchers();
}

class VoucherRemoteDataSourceImpl implements VoucherRemoteDataSource {
  VoucherRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<VoucherDto>> getVouchers() async {
    try {
      await apiClient.ensureInitialized();

      final url = ApiEndpoints.getVouchers;
      print('📤 Fetching vouchers: $url');

      final response = await apiClient.dio.get(url);
      print('📥 Vouchers response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<VoucherDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          final list = data as List<dynamic>;
          return list
              .map((e) => VoucherDto.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      if (apiResponse.code != 200) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data ?? [];
    } on DioException catch (e) {
      print('❌ DioException vouchers: ${e.type} — ${e.message}');
      if (e.response != null) {
        final body = e.response!.data;
        if (body is Map<String, dynamic> && body['message'] != null) {
          throw Exception(body['message'] as String);
        }
      }
      throw Exception('Không thể kết nối đến server');
    } catch (e) {
      print('❌ Vouchers error: $e');
      rethrow;
    }
  }
}
