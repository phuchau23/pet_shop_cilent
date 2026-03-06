import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  // Danh sách các endpoint KHÔNG cần token (public endpoints)
  static const List<String> _publicEndpoints = [
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
  ];

  // Kiểm tra xem endpoint có phải là public không
  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Nếu là public endpoint, không thêm token
    if (_isPublicEndpoint(options.path)) {
      print('🌐 Public endpoint - skipping token: ${options.uri}');
      print('📋 Request headers (public): ${options.headers}');
      print('📋 Request method: ${options.method}');
      print('📋 Request data: ${options.data}');
      super.onRequest(options, handler);
      return;
    }

    // Lấy token từ storage
    final token = await TokenStorage.getToken();

    // Nếu có token, thêm vào header
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 Adding token to request: ${options.uri}');
      print(
        '🔑 Token (first 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...',
      );
    } else {
      print('⚠️ No token found for request: ${options.uri}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Nếu lỗi 401 (Unauthorized)
    if (err.response?.statusCode == 401) {
      final isPublicEndpoint = _isPublicEndpoint(err.requestOptions.path);
      if (isPublicEndpoint) {
        print('⚠️ 401 on public endpoint - Request: ${err.requestOptions.uri}');
        print('⚠️ This might be a login/register error, not token issue');
      } else {
        print(
          '⚠️ Token expired or invalid (401) - Request: ${err.requestOptions.uri}',
        );
      }
      // Log response để debug
      if (err.response?.data != null) {
        print('⚠️ 401 Response data: ${err.response?.data}');
      }
    }

    super.onError(err, handler);
  }
}
