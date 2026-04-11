import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/remote/shipper_remote_data_source.dart';
import '../data/models/update_shipper_location_request_dto.dart';

class LocationTrackingService {
  int? _currentOrderId;
  final ShipperRemoteDataSource _dataSource;
  Timer? _locationUpdateTimer;

  LocationTrackingService()
      : _dataSource = ShipperRemoteDataSourceImpl(apiClient: ApiClient());

  /// Bắt đầu tracking GPS và gửi location lên server mỗi 5 giây
  Future<void> startTracking(int orderId) async {
    await stopTracking();

    _currentOrderId = orderId;

    // Kiểm tra permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Please enable it in settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever. Please enable it in settings.');
    }

    print('📍 Starting location tracking for order $orderId');

    // Gửi ngay lập tức lần đầu
    await _sendCurrentLocation(orderId);

    // Timer mỗi 5 giây gọi getCurrentPosition() - luôn lấy vị trí hiện tại,
    // hoạt động đúng cả trên emulator khi chỉnh mock location
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendCurrentLocation(orderId);
    });
  }

  /// Lấy vị trí hiện tại và gửi lên server
  Future<void> _sendCurrentLocation(int orderId) async {
    try {
      Position? position;

      try {
        // forceLocationManager=true: dùng legacy LocationManager thay vì FusedLocationProvider
        // FusedLocationProvider không đọc được mock location từ Extended Controls trên emulator
        // accuracy.best + forceLocationManager=true → dùng GPS_PROVIDER trực tiếp
        // Extended Controls inject mock vào GPS_PROVIDER, NETWORK_PROVIDER không nhận mock
        position = await Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            forceLocationManager: true,
          ),
        ).first.timeout(const Duration(seconds: 8));
      } catch (_) {
        // Fallback: last known (không timeout)
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return;

      await _dataSource.updateShipperLocation(
        orderId,
        UpdateShipperLocationRequestDto(lat: position.latitude, lng: position.longitude),
      );
      print('✅ Location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error sending location: $e');
    }
  }

  /// Dừng tracking GPS
  Future<void> stopTracking() async {
    print('🛑 Stopping location tracking');
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _currentOrderId = null;
  }

  int? get currentOrderId => _currentOrderId;
  bool get isTracking => _locationUpdateTimer != null;
}
