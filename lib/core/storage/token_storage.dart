import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyExpiresAt = 'expires_at';

  // Lưu token
  static Future<void> saveToken({
    required String token,
    String? refreshToken,
    String? expiresAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }
      if (expiresAt != null) {
        await prefs.setString(_keyExpiresAt, expiresAt);
      }
      print('💾 Token saved successfully');
    } catch (e) {
      print('❌ Error saving token: $e');
      // Không throw để tránh crash app
    }
  }

  // Lấy token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  // Lấy refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  // Lấy expires at
  static Future<String?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyExpiresAt);
  }

  // Xóa token (logout)
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyExpiresAt);
      print('🗑️ Token cleared');
    } catch (e) {
      print('❌ Error clearing token: $e');
      // Không throw để tránh crash app
    }
  }

  // Kiểm tra đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }
}
