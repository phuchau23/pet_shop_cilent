import 'package:shared_preferences/shared_preferences.dart';

class StoreStorage {
  static const String _keyStoreLat = 'store_latitude';
  static const String _keyStoreLng = 'store_longitude';
  static const String _keyStoreAddress = 'store_address';

  // Địa chỉ cửa hàng mặc định (HCM)
  static const double defaultLat = 10.762622;
  static const double defaultLng = 106.660172;
  static const String defaultAddress = '123 Đường ABC, Quận 1, TP. Hồ Chí Minh';

  /// Lưu địa chỉ cửa hàng
  static Future<void> saveStoreLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyStoreLat, latitude);
      await prefs.setDouble(_keyStoreLng, longitude);
      await prefs.setString(_keyStoreAddress, address);
      print('💾 Store location saved');
    } catch (e) {
      print('❌ Error saving store location: $e');
    }
  }

  /// Lấy latitude cửa hàng
  static Future<double> getStoreLatitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyStoreLat) ?? defaultLat;
    } catch (e) {
      print('❌ Error getting store latitude: $e');
      return defaultLat;
    }
  }

  /// Lấy longitude cửa hàng
  static Future<double> getStoreLongitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyStoreLng) ?? defaultLng;
    } catch (e) {
      print('❌ Error getting store longitude: $e');
      return defaultLng;
    }
  }

  /// Lấy địa chỉ cửa hàng
  static Future<String> getStoreAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyStoreAddress) ?? defaultAddress;
    } catch (e) {
      print('❌ Error getting store address: $e');
      return defaultAddress;
    }
  }
}
