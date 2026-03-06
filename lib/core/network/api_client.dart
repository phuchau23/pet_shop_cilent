import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  // Nếu chạy trên Chrome (web), dùng: 'http://localhost:5000/api'
  // Nếu chạy trên Android Emulator, dùng: 'http://10.0.2.2:5000/api'
  // Nếu chạy trên iOS Simulator, dùng: 'http://localhost:5000/api'
  // Nếu chạy trên thiết bị thật, dùng IP máy tính: 'http://192.168.1.xxx:5000/api'

  static String get baseUrl {
    // Kiểm tra nếu đang chạy trên web (Chrome)
    if (kIsWeb) {
      // Chrome/Web browser - dùng 127.0.0.1 thay vì localhost để tránh CORS issues
      // Nếu vẫn lỗi, có thể cần cấu hình CORS trên server hoặc dùng proxy
      return 'http://127.0.0.1:5000/api';
    } else {
      // Kiểm tra platform bằng defaultTargetPlatform (an toàn cho cả web và mobile)
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android Emulator
        return 'http://10.0.2.2:5000/api';
      } else {
        // iOS Simulator hoặc thiết bị thật
        // Nếu thiết bị thật, thay bằng IP máy tính của bạn
        return 'http://localhost:5000/api';
      }
    }
  }

  late final Dio _dio;

  ApiClient() {
    print('🌐 API Base URL: $baseUrl'); // Debug log
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}'); // Debug log

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Thêm validateStatus để không throw error cho status codes
        validateStatus: (status) {
          return status != null && status < 500; // Chỉ throw error cho 5xx
        },
      ),
    );

    // Thêm AuthInterceptor để tự động thêm token vào header
    _dio.interceptors.add(AuthInterceptor());
  }

  Dio get dio => _dio;
}
