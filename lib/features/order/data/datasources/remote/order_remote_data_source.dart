import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../models/estimate_delivery_request_dto.dart';
import '../../models/estimate_delivery_response_dto.dart';
import '../../models/validate_voucher_request_dto.dart';
import '../../models/voucher_response_dto.dart';
import '../../models/create_order_request_dto.dart';
import '../../models/create_order_response_dto.dart';
import '../../models/order_tracking_response_dto.dart';
import '../../models/order_list_item_dto.dart';

abstract class OrderRemoteDataSource {
  Future<EstimateDeliveryResponseDto> estimateDelivery(
    EstimateDeliveryRequestDto request,
  );
  Future<VoucherResponseDto> validateVoucher(ValidateVoucherRequestDto request);
  Future<List<VoucherResponseDto>> getVouchers();
  Future<CreateOrderResponseDto> createOrder(CreateOrderRequestDto request);
  Future<OrderTrackingResponseDto> getOrderTracking(int orderId);
  Future<List<OrderListItemDto>> getOrders({String? status});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<EstimateDeliveryResponseDto> estimateDelivery(
    EstimateDeliveryRequestDto request,
  ) async {
    try {
      print(
        '📤 Estimating delivery: ${ApiClient.baseUrl}${ApiEndpoints.estimateDelivery}',
      );
      print('📤 Request: ${request.toJson()}');

      final response = await apiClient.dio.post(
        ApiEndpoints.estimateDelivery,
        data: request.toJson(),
      );

      print('📥 Estimate delivery response status: ${response.statusCode}');

      final apiResponse = ApiResponse<EstimateDeliveryResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) =>
            EstimateDeliveryResponseDto.fromJson(data as Map<String, dynamic>),
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi ước tính thời gian giao hàng.');
    }
  }

  @override
  Future<VoucherResponseDto> validateVoucher(
    ValidateVoucherRequestDto request,
  ) async {
    try {
      print(
        '📤 Validating voucher: ${ApiClient.baseUrl}${ApiEndpoints.validateVoucher}',
      );
      print('📤 Request: ${request.toJson()}');

      final response = await apiClient.dio.post(
        ApiEndpoints.validateVoucher,
        data: request.toJson(),
      );

      print('📥 Validate voucher response status: ${response.statusCode}');

      final apiResponse = ApiResponse<VoucherResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => VoucherResponseDto.fromJson(data as Map<String, dynamic>),
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi validate voucher.');
    }
  }

  @override
  Future<List<VoucherResponseDto>> getVouchers() async {
    try {
      print(
        '📤 Getting vouchers: ${ApiClient.baseUrl}${ApiEndpoints.getVouchers}',
      );

      final response = await apiClient.dio.get(ApiEndpoints.getVouchers);

      print('📥 Get vouchers response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as List<dynamic>,
      );

      if (apiResponse.data != null) {
        return apiResponse.data!
            .map(
              (json) =>
                  VoucherResponseDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy danh sách voucher.');
    }
  }

  @override
  Future<CreateOrderResponseDto> createOrder(
    CreateOrderRequestDto request,
  ) async {
    try {
      print(
        '📤 Creating order: ${ApiClient.baseUrl}${ApiEndpoints.createOrder}',
      );
      print('📤 Request: ${request.toJson()}');

      final response = await apiClient.dio.post(
        ApiEndpoints.createOrder,
        data: request.toJson(),
      );

      print('📥 Create order response status: ${response.statusCode}');

      final apiResponse = ApiResponse<CreateOrderResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CreateOrderResponseDto.fromJson(data as Map<String, dynamic>),
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi tạo đơn hàng.');
    }
  }

  @override
  Future<OrderTrackingResponseDto> getOrderTracking(int orderId) async {
    try {
      print(
        '📤 Getting order tracking: ${ApiClient.baseUrl}${ApiEndpoints.orderTracking}/$orderId/tracking',
      );

      final response = await apiClient.dio.get(
        '${ApiEndpoints.orderTracking}/$orderId/tracking',
      );

      print('📥 Order tracking response status: ${response.statusCode}');
      print('📥 Order tracking response data (raw): ${response.data}');
      
      // Parse response để kiểm tra structure
      final responseData = response.data as Map<String, dynamic>;
      print('📥 Response structure:');
      print('  - Has "data" key: ${responseData.containsKey('data')}');
      print('  - Has "code" key: ${responseData.containsKey('code')}');
      print('  - Has "message" key: ${responseData.containsKey('message')}');
      
      if (responseData.containsKey('data')) {
        final dataMap = responseData['data'] as Map<String, dynamic>?;
        if (dataMap != null) {
          print('📥 Data object keys: ${dataMap.keys.toList()}');
          print('📥 Location fields in data:');
          print('  - shopLat: ${dataMap['shopLat']} (type: ${dataMap['shopLat'].runtimeType})');
          print('  - shopLng: ${dataMap['shopLng']} (type: ${dataMap['shopLng'].runtimeType})');
          print('  - customerLat: ${dataMap['customerLat']} (type: ${dataMap['customerLat'].runtimeType})');
          print('  - customerLng: ${dataMap['customerLng']} (type: ${dataMap['customerLng'].runtimeType})');
          print('  - shipperCurrentLat: ${dataMap['shipperCurrentLat']} (type: ${dataMap['shipperCurrentLat'].runtimeType})');
          print('  - shipperCurrentLng: ${dataMap['shipperCurrentLng']} (type: ${dataMap['shipperCurrentLng'].runtimeType})');
        }
      }

      final apiResponse = ApiResponse<OrderTrackingResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) {
          print('📥 Parsing tracking data: $data');
          return OrderTrackingResponseDto.fromJson(data as Map<String, dynamic>);
        },
      );

      if (apiResponse.data != null) {
        print('✅ Tracking data parsed successfully');
        print('  - shopLat: ${apiResponse.data!.shopLat}, shopLng: ${apiResponse.data!.shopLng}');
        print('  - customerLat: ${apiResponse.data!.customerLat}, customerLng: ${apiResponse.data!.customerLng}');
        print('  - shipperCurrentLat: ${apiResponse.data!.shipperCurrentLat}, shipperCurrentLng: ${apiResponse.data!.shipperCurrentLng}');
        
        // Warning nếu location data vẫn null
        if (apiResponse.data!.shopLat == null || apiResponse.data!.shopLng == null) {
          print('⚠️ WARNING: shopLat/shopLng is NULL - Backend chưa trả về shop location!');
        }
        if (apiResponse.data!.customerLat == null || apiResponse.data!.customerLng == null) {
          print('⚠️ WARNING: customerLat/customerLng is NULL - Backend chưa trả về customer location!');
        }
        if (apiResponse.data!.shipperCurrentLat == null || apiResponse.data!.shipperCurrentLng == null) {
          print('⚠️ INFO: shipperCurrentLat/shipperCurrentLng is NULL - Shipper chưa gửi location hoặc chưa bắt đầu di chuyển');
        }
        
        return apiResponse.data!;
      } else {
        print('❌ Tracking data is null, message: ${apiResponse.message}');
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy thông tin tracking đơn hàng.');
    }
  }

  @override
  Future<List<OrderListItemDto>> getOrders({String? status}) async {
    try {
      // ⭐ Dùng API mới /api/orders/my-orders - tự động lấy từ token
      final queryParams = <String, dynamic>{};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      print(
        '📤 Getting orders: ${ApiClient.baseUrl}${ApiEndpoints.getMyOrders}',
      );
      if (status != null) {
        print('📤 Filter by status: $status');
      }

      final response = await apiClient.dio.get(
        ApiEndpoints.getMyOrders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 Get orders response status: ${response.statusCode}');

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) =>
            (data as List).map((item) => item as Map<String, dynamic>).toList(),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => OrderListItemDto.fromJson(item))
            .toList();
      } else {
        return [];
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
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }

      if (e.response != null) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (data) => data,
        );
        throw Exception(apiResponse.message);
      }

      throw Exception('Đã xảy ra lỗi khi lấy danh sách đơn hàng.');
    }
  }
}
