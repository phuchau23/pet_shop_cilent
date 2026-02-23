import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';

  // Lưu thông tin user
  static Future<void> saveUser({
    required int userId,
    required String email,
    required String fullName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserFullName, fullName);
      print('💾 User info saved: userId=$userId');
    } catch (e) {
      print('❌ Error saving user info: $e');
    }
  }

  // Lấy user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUserId);
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }

  // Lấy email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('❌ Error getting user email: $e');
      return null;
    }
  }

  // Lấy full name
  static Future<String?> getUserFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserFullName);
    } catch (e) {
      print('❌ Error getting user full name: $e');
      return null;
    }
  }

  // Xóa thông tin user (logout)
  static Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserFullName);
      print('🗑️ User info cleared');
    } catch (e) {
      print('❌ Error clearing user info: $e');
    }
  }
}
