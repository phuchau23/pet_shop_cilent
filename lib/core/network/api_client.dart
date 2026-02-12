import 'dart:io';
import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  // Nếu chạy trên Android Emulator, dùng: 'http://10.0.2.2:5000/api'
  // Nếu chạy trên iOS Simulator hoặc web, dùng: 'http://localhost:5000/api'
  // Nếu chạy trên thiết bị thật, dùng IP máy tính: 'http://192.168.1.xxx:5000/api'

  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android Emulator
      return 'http://10.0.2.2:5000/api';
    } else {
      // iOS Simulator, Web, hoặc thiết bị thật
      // Nếu thiết bị thật, thay bằng IP máy tính của bạn
      return 'http://localhost:5000/api';
    }
  }

  late final Dio _dio;

  ApiClient() {
    print('🌐 API Base URL: $baseUrl'); // Debug log
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Thêm AuthInterceptor để tự động thêm token vào header
    _dio.interceptors.add(AuthInterceptor());
  }

  Dio get dio => _dio;
}
