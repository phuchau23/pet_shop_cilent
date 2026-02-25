import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../models/google_login_request_dto.dart';
import '../../models/login_request_dto.dart';
import '../../models/login_response_dto.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);
  Future<LoginResponseDto> loginWithGoogle(GoogleLoginRequestDto request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      print(
        '📤 Sending login request to: ${ApiClient.baseUrl}${ApiEndpoints.login}',
      );
      print('📤 Request data: ${request.toJson()}');

      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      return _parseAuthResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<LoginResponseDto> loginWithGoogle(
    GoogleLoginRequestDto request,
  ) async {
    try {
      print(
        '📤 Sending Google login request to: ${ApiClient.baseUrl}${ApiEndpoints.googleLogin}',
      );
      print('📤 Request data: {idToken: [REDACTED]}');

      final response = await apiClient.dio.post(
        ApiEndpoints.googleLogin,
        data: request.toJson(),
      );

      return _parseAuthResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  LoginResponseDto _parseAuthResponse(Response<dynamic> response) {
    print('Response status: ${response.statusCode}');
    print('Response data: ${response.data}');

    final apiResponse = ApiResponse<LoginResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LoginResponseDto.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.message);
    }
  }

  Never _handleDioError(DioException e) {
    print('DioException: ${e.type}');
    print('Error message: ${e.message}');
    print('Response: ${e.response?.data}');
    print('Status code: ${e.response?.statusCode}');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw Exception('Kết nối timeout. Vui lòng kiểm tra kết nối mạng.');
    }

    if (e.type == DioExceptionType.connectionError) {
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra URL và đảm bảo server đang chạy.',
      );
    }

    if (e.response != null) {
      final errorData = e.response!.data;
      if (errorData is Map<String, dynamic>) {
        throw Exception(errorData['message'] ?? 'Đăng nhập thất bại');
      } else {
        throw Exception('Đăng nhập thất bại: ${e.response?.statusCode}');
      }
    } else {
      throw Exception('Không thể kết nối đến server: ${e.message}');
    }
  }
}
