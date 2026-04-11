import 'package:shared_preferences/shared_preferences.dart';

class StoreStorage {
  static const String _keyStoreLat = 'store_latitude';
  static const String _keyStoreLng = 'store_longitude';
  static const String _keyStoreAddress = 'store_address';

  // Đại học FPT TP.HCM — Khu CNC, Long Thạnh Mỹ, TP. Thủ Đức (cũ Q.9)
  static const double defaultLat = 10.841182;
  static const double defaultLng = 106.809883;
  static const String defaultAddress =
      'Đại học FPT, Khu CNC, P. Long Thạnh Mỹ, TP. Thủ Đức, TP. Hồ Chí Minh';

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
