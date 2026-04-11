import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../models/shipper_order_response_dto.dart';
import '../../models/update_shipper_status_request_dto.dart';
import '../../models/update_shipper_location_request_dto.dart';

abstract class ShipperRemoteDataSource {
  Future<List<ShipperOrderResponseDto>> getMyOrders({String? status});
  Future<List<ShipperOrderResponseDto>> getAvailableOrders();
  Future<ShipperOrderResponseDto> updateShipperStatus(
    int orderId,
    UpdateShipperStatusRequestDto request,
  );
  Future<void> updateShipperLocation(
    int orderId,
    UpdateShipperLocationRequestDto request,
  );
}

class ShipperRemoteDataSourceImpl implements ShipperRemoteDataSource {
  final ApiClient apiClient;

  ShipperRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ShipperOrderResponseDto>> getMyOrders({String? status}) async {
    try {
      print('📤 Getting shipper orders: status=$status');

      String url = ApiEndpoints.getShipperOrders;
      if (status != null && status.isNotEmpty) {
        url = ApiEndpoints.buildUrlWithQuery(
          ApiEndpoints.getShipperOrders,
          queryParams: {'status': status},
        );
      }

      final response = await apiClient.dio.get(url);

      print('📥 Shipper orders response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<ShipperOrderResponseDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List<dynamic>)
            .map(
              (item) => ShipperOrderResponseDto.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

      if (apiResponse.data != null) {
        print('✅ Got ${apiResponse.data!.length} shipper orders');
        return apiResponse.data!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: apiResponse.message,
        );
      }
    } on DioException catch (e) {
      print('❌ Error getting shipper orders: ${e.message}');
      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error getting shipper orders: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<List<ShipperOrderResponseDto>> getAvailableOrders() async {
    try {
      print('📤 Getting available orders');

      final response = await apiClient.dio.get(ApiEndpoints.getAvailableOrders);

      print('📥 Available orders response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<ShipperOrderResponseDto>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => (data as List<dynamic>)
            .map(
              (item) => ShipperOrderResponseDto.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

      if (apiResponse.data != null) {
        print('✅ Got ${apiResponse.data!.length} available orders');
        return apiResponse.data!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: apiResponse.message,
        );
      }
    } on DioException catch (e) {
      print('❌ Error getting available orders: ${e.message}');
      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error getting available orders: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<ShipperOrderResponseDto> updateShipperStatus(
    int orderId,
    UpdateShipperStatusRequestDto request,
  ) async {
    try {
      print('📤 Updating shipper status for order $orderId: ${request.status}');

      final url = '${ApiEndpoints.updateShipperStatus}/$orderId/shipper-status';

      final response = await apiClient.dio.patch(url, data: request.toJson());

      print('📥 Update shipper status response status: ${response.statusCode}');

      final apiResponse = ApiResponse<ShipperOrderResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) =>
            ShipperOrderResponseDto.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        print('✅ Shipper status updated successfully');
        return apiResponse.data!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: apiResponse.message,
        );
      }
    } on DioException catch (e) {
      print('❌ Error updating shipper status: ${e.message}');
      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error updating shipper status: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateShipperLocation(
    int orderId,
    UpdateShipperLocationRequestDto request,
  ) async {
    try {
      print(
        '📤 Updating shipper location for order $orderId: ${request.lat}, ${request.lng}',
      );

      final url =
          '${ApiEndpoints.updateShipperLocation}/$orderId/shipper-location';

      final response = await apiClient.dio.post(url, data: request.toJson());

      print(
        '📥 Update shipper location response status: ${response.statusCode}',
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data,
      );

      if (apiResponse.code == 200) {
        print('✅ Shipper location updated successfully');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: apiResponse.message,
        );
      }
    } on DioException catch (e) {
      print('❌ Error updating shipper location: ${e.message}');
      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error updating shipper location: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
