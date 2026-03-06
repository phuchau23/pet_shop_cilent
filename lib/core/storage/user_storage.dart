import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserRole = 'user_role';

  // Lưu thông tin user
  static Future<void> saveUser({
    required int userId,
    required String email,
    required String fullName,
    String? phone,
    String? userRole,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserFullName, fullName);
      if (phone != null) {
        await prefs.setString(_keyUserPhone, phone);
      }
      if (userRole != null) {
        await prefs.setString(_keyUserRole, userRole);
      }
      print('💾 User info saved: userId=$userId, role=$userRole');
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

  // Lấy phone number
  static Future<String?> getUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserPhone);
    } catch (e) {
      print('❌ Error getting user phone: $e');
      return null;
    }
  }

  // Lấy user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserRole);
    } catch (e) {
      print('❌ Error getting user role: $e');
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
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyUserRole);
      print('🗑️ User info cleared');
    } catch (e) {
      print('❌ Error clearing user info: $e');
    }
  }
}
