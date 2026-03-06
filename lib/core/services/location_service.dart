import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Kiểm tra và yêu cầu quyền truy cập location
  static Future<bool> requestPermission() async {
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Mở settings để user bật permission
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Lấy vị trí hiện tại
  static Future<Position?> getCurrentLocation() async {
    try {
      // Kiểm tra permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Kiểm tra location service có bật không
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Lấy vị trí với độ chính xác cao
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Lấy vị trí cập nhật liên tục (stream)
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update mỗi 10 mét
      ),
    );
  }

  /// Tính khoảng cách giữa 2 điểm (mét)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
