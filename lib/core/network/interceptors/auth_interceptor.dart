import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Lấy token từ storage
    final token = await TokenStorage.getToken();

    // Nếu có token, thêm vào header
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 Adding token to request: ${options.uri}');
    } else {
      print('⚠️ No token found for request: ${options.uri}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Nếu lỗi 401 (Unauthorized), có thể token đã hết hạn
    if (err.response?.statusCode == 401) {
      print('❌ Unauthorized - Token may be expired');
      // Có thể thêm logic refresh token ở đây
    }

    super.onError(err, handler);
  }
}
