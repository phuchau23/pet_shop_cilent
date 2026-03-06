import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_response.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../models/google_login_request_dto.dart';
import '../../models/login_request_dto.dart';
import '../../models/login_response_dto.dart';
import '../../models/profile_response_dto.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);
  Future<ProfileResponseDto> getProfile();
  Future<void> logout();
  Future<LoginResponseDto> loginWithGoogle(GoogleLoginRequestDto request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      // Kiểm tra xem có token cũ không (để debug)
      final oldToken = await TokenStorage.getToken();
      if (oldToken != null) {
        print('⚠️ Found old token in storage (will be ignored for login)');
      }

      final fullUrl = '${ApiClient.baseUrl}${ApiEndpoints.login}';
      print('📤 Sending login request to: $fullUrl');
      print('📤 Request data: ${request.toJson()}');
      print('📤 Base URL: ${ApiClient.baseUrl}');
      print('📤 Endpoint: ${ApiEndpoints.login}');

      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
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
    if (e.response != null) {
      final errorData = e.response!.data;
      print('❌ Error response data type: ${errorData.runtimeType}');
      print('❌ Error response data: $errorData');

      if (errorData is Map<String, dynamic>) {
        // Thử parse theo format ApiResponse
        try {
          final apiResponse = ApiResponse<dynamic>.fromJson(
            errorData,
            (data) => data,
          );
          throw Exception(
            apiResponse.message.isNotEmpty
                ? apiResponse.message
                : 'Đăng nhập thất bại',
          );
        } catch (parseError) {
          // Nếu không parse được ApiResponse, thử lấy message trực tiếp
          final message =
              errorData['message'] ??
              errorData['title'] ??
              errorData['detail'] ??
              'Đăng nhập thất bại';
          throw Exception(message.toString());
        }
      } else if (errorData is String) {
        throw Exception(errorData);
      } else {
        throw Exception('Đăng nhập thất bại: ${e.response?.statusCode}');
      }
    } else {
      throw Exception('Không thể kết nối đến server: ${e.message}');
    }
  }

  @override
  Future<ProfileResponseDto> getProfile() async {
    try {
      print(
        '📤 Getting profile: ${ApiClient.baseUrl}${ApiEndpoints.getAuthProfile}',
      );

      final response = await apiClient.dio.get(ApiEndpoints.getAuthProfile);

      print('📥 Get profile response status: ${response.statusCode}');

      final apiResponse = ApiResponse<ProfileResponseDto>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ProfileResponseDto.fromJson(data as Map<String, dynamic>),
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

      throw Exception('Đã xảy ra lỗi khi lấy thông tin profile.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      print('📤 Logging out: ${ApiClient.baseUrl}${ApiEndpoints.logout}');

      final response = await apiClient.dio.post(ApiEndpoints.logout);

      print('📥 Logout response status: ${response.statusCode}');
      print('✅ Logout successful');
    } on DioException catch (e) {
      // Không throw error vì dù API fail thì vẫn cần xóa local storage
      print('⚠️ Logout API error (continuing with local logout): ${e.message}');
      if (e.response != null) {
        print('⚠️ Response: ${e.response?.data}');
        print('⚠️ Status code: ${e.response?.statusCode}');
      }
    } catch (e) {
      // Không throw error vì dù API fail thì vẫn cần xóa local storage
      print('⚠️ Logout error (continuing with local logout): $e');
    }
  }
}
