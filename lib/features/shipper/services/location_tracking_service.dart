import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/remote/shipper_remote_data_source.dart';
import '../data/models/update_shipper_location_request_dto.dart';

class LocationTrackingService {
  StreamSubscription<Position>? _positionStream;
  int? _currentOrderId;
  final ShipperRemoteDataSource _dataSource;
  Timer? _locationUpdateTimer;

  LocationTrackingService()
      : _dataSource = ShipperRemoteDataSourceImpl(apiClient: ApiClient());

  /// Bắt đầu tracking GPS và gửi location lên server
  Future<void> startTracking(int orderId) async {
    // Stop existing tracking if any
    await stopTracking();

    _currentOrderId = orderId;

    // Request permission
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

    // Listen to position changes
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update mỗi 10 mét
      ),
    ).listen(
      (Position position) {
        // Gửi location lên server
        _sendLocationToServer(orderId, position.latitude, position.longitude);
      },
      onError: (error) {
        print('❌ Error in position stream: $error');
      },
    );

    // Gửi location ngay lập tức
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sendLocationToServer(orderId, currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      print('⚠️ Could not get current position: $e');
    }
  }

  /// Gửi location lên server
  Future<void> _sendLocationToServer(int orderId, double lat, double lng) async {
    try {
      await _dataSource.updateShipperLocation(
        orderId,
        UpdateShipperLocationRequestDto(lat: lat, lng: lng),
      );
      print('✅ Location sent: $lat, $lng');
    } catch (e) {
      print('❌ Error sending location: $e');
      // Không throw để không làm gián đoạn tracking
    }
  }

  /// Dừng tracking GPS
  Future<void> stopTracking() async {
    print('🛑 Stopping location tracking');
    await _positionStream?.cancel();
    _positionStream = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _currentOrderId = null;
  }

  int? get currentOrderId => _currentOrderId;
  bool get isTracking => _positionStream != null;
}
