import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  // Backend deploy (Render): https://pet-shop-ydyr.onrender.com/api/...
  // Đặt false để dev với BE chạy local (localhost / emulator / IP LAN).
  static const bool _useDeployedBackend = true;
  static const String _deployedBaseUrl =
      'https://pet-shop-ydyr.onrender.com/api';

  // Nếu chạy trên Chrome (web), dùng: 'http://localhost:5000/api'
  // Nếu chạy trên Android Emulator, dùng: 'http://10.0.2.2:5000/api'
  // Nếu chạy trên iOS Simulator, dùng: 'http://localhost:5000/api'
  // Nếu chạy trên thiết bị thật, dùng IP máy tính: 'http://192.168.1.10:5000/api'

  // Flag để bật/tắt phát hiện thiết bị thật tự động
  // Nếu true, sẽ tự động phát hiện thiết bị thật và dùng IP 192.168.1.4
  // Nếu false, sẽ dùng emulator/simulator URLs
  static const bool _autoDetectRealDevice = true;

  // Flag để force dùng IP thiết bị thật (bỏ qua phát hiện)
  // Nếu true, sẽ luôn dùng IP thiết bị thật khi không phải web
  // Hữu ích khi phát hiện tự động không chính xác
  // Đặt true nếu bạn chắc chắn đang chạy trên thiết bị thật
  // ⚠️ Đặt false nếu chạy trên emulator để dùng 10.0.2.2
  static const bool _forceRealDeviceIP = false;

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static bool? _isRealDeviceCache;
  static Future<bool>? _deviceCheckFuture;

  /// Kiểm tra xem có đang chạy trên thiết bị thật không (async)
  static Future<bool> _checkIsRealDevice() async {
    if (kIsWeb || !_autoDetectRealDevice) return false;

    // Sử dụng cache để tránh kiểm tra nhiều lần
    if (_isRealDeviceCache != null) return _isRealDeviceCache!;
    
    // Nếu đang có một check đang chạy, đợi nó hoàn thành
    if (_deviceCheckFuture != null) {
      return await _deviceCheckFuture!;
    }
    
    // Tạo future mới và cache nó
    _deviceCheckFuture = _performDeviceCheck();
    final result = await _deviceCheckFuture!;
    return result;
  }
  
  static Future<bool> _performDeviceCheck() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // Emulator thường có model chứa "sdk", "google_sdk", "Emulator", hoặc "Android SDK"
        final model = androidInfo.model.toLowerCase();
        final brand = androidInfo.brand.toLowerCase();
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final fingerprint = androidInfo.fingerprint.toLowerCase();

        // Kiểm tra các dấu hiệu của emulator
        final isEmulator =
            model.contains('sdk') ||
            model.contains('emulator') ||
            model.contains('google_sdk') ||
            model == 'unknown' ||
            brand.contains('generic') ||
            brand == 'unknown' ||
            manufacturer.contains('generic') ||
            manufacturer == 'unknown' ||
            fingerprint.contains('generic') ||
            fingerprint.contains('test-keys') ||
            fingerprint.contains('unknown');

        _isRealDeviceCache = !isEmulator;
        return _isRealDeviceCache!;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        // Simulator có name chứa "Simulator" hoặc identifierForVendor là null
        final name = iosInfo.name.toLowerCase();
        final isSimulator =
            name.contains('simulator') ||
            iosInfo.utsname.machine.contains('simulator') ||
            iosInfo.model.contains('simulator') ||
            iosInfo.model.contains('iphone simulator') ||
            iosInfo.model.contains('ipad simulator');

        _isRealDeviceCache = !isSimulator;
        return _isRealDeviceCache!;
      }
    } catch (e) {
      // Nếu có lỗi khi kiểm tra, mặc định là emulator/simulator
      print('⚠️ Error checking device type: $e');
      _isRealDeviceCache = false;
      return false;
    }
    _isRealDeviceCache = false;
    return false;
  }

  static String get baseUrl {
    if (_useDeployedBackend) {
      return _deployedBaseUrl;
    }

    // Kiểm tra nếu đang chạy trên web (Chrome)
    if (kIsWeb) {
      // Chrome/Web browser - dùng 127.0.0.1 thay vì localhost để tránh CORS issues
      return 'http://127.0.0.1:5000/api';
    } else {
      // Nếu force real device IP, dùng IP thiết bị thật ngay từ đầu
      if (_forceRealDeviceIP) {
        return 'http://192.168.1.7:5000/api';
      }

      // Kiểm tra platform bằng defaultTargetPlatform (an toàn cho cả web và mobile)
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android - mặc định dùng emulator URL
        // Sẽ được kiểm tra async và cập nhật nếu là thiết bị thật
        return 'http://10.0.2.2:5000/api';
      } else {
        // iOS - mặc định dùng localhost (simulator)
        // Sẽ được kiểm tra async và cập nhật nếu là thiết bị thật
        return 'http://localhost:5000/api';
      }
    }
  }

  late final Dio _dio;
  late String _actualBaseUrl;
  Future<void>? _initializationFuture;

  ApiClient() {
    // Khởi tạo với baseUrl (sẽ là IP thiết bị thật nếu _forceRealDeviceIP = true)
    _actualBaseUrl = baseUrl;
    
    // Log để debug
    print('🌐 ApiClient constructor - Initial baseUrl: $_actualBaseUrl');
    print('🌐 Force real device IP: $_forceRealDeviceIP');
    print('🌐 Is Web: $kIsWeb');
    print('🌐 Platform: ${defaultTargetPlatform == TargetPlatform.android ? "Android" : "iOS"}');

    // Khởi tạo Dio ngay với baseUrl
    _dio = Dio(
      BaseOptions(
        baseUrl: _actualBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    print('🌐 Dio initialized with baseUrl: ${_dio.options.baseUrl}');

    // Thêm AuthInterceptor để tự động thêm token vào header
    _dio.interceptors.add(AuthInterceptor());

    // Bắt đầu kiểm tra thiết bị thật async và cập nhật baseUrl nếu cần
    _initializationFuture = _updateBaseUrlIfRealDevice();
  }

  /// Đợi baseUrl được khởi tạo xong (quan trọng khi chạy trên thiết bị thật)
  Future<void> ensureInitialized() async {
    if (_initializationFuture != null) {
      await _initializationFuture;
    }
  }

  Future<void> _updateBaseUrlIfRealDevice() async {
    if (kIsWeb || _useDeployedBackend) return;

    try {
      bool isRealDevice = false;

      if (_forceRealDeviceIP) {
        // Force dùng IP thiết bị thật (bỏ qua phát hiện)
        isRealDevice = true;
      } else {
        // Phát hiện tự động (sẽ dùng cache nếu đã check trước đó)
        isRealDevice = await _checkIsRealDevice();
      }

      if (isRealDevice) {
        // Thiết bị thật - cập nhật baseUrl (cập nhật IP mới nhất: 192.168.1.7)
        final newBaseUrl = defaultTargetPlatform == TargetPlatform.android
            ? 'http://192.168.1.7:5000/api'
            : 'http://192.168.1.7:5000/api';

        // Chỉ cập nhật nếu khác với baseUrl hiện tại
        if (_actualBaseUrl != newBaseUrl) {
          _actualBaseUrl = newBaseUrl;
          _dio.options.baseUrl = newBaseUrl;
          print('🌐 ✅ Updated API Base URL for real device: $_actualBaseUrl');
        }
      }
    } catch (e) {
      print('⚠️ Error updating base URL: $e');
      
      // Nếu có lỗi và đang chạy trên mobile (không phải web),
      // có thể là thiết bị thật nhưng phát hiện fail -> dùng IP thật
      if (!kIsWeb && _forceRealDeviceIP) {
        final fallbackUrl = defaultTargetPlatform == TargetPlatform.android
            ? 'http://192.168.1.7:5000/api'
            : 'http://192.168.1.7:5000/api';
        if (_actualBaseUrl != fallbackUrl) {
          _actualBaseUrl = fallbackUrl;
          _dio.options.baseUrl = fallbackUrl;
        }
      }
    }
  }

  Dio get dio => _dio;
}
