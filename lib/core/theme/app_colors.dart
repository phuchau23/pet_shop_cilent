import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo: Pastel Pink (màu pastel hồng nhẹ nhàng, phù hợp pet shop)
  static const Color primary = Color(0xFFFFB6C1); // Pastel Pink (Light Pink)
  static const Color primaryLight = Color(0xFFFFC0CB); // Pink Light
  static const Color primaryDark = Color(0xFFFF91A4); // Pink Dark
  static const Color primaryVeryLight = Color(0xFFFFF0F5); // Pink Very Light (Lavender Blush)

  // Màu phụ: Pastel Blue (xanh dương pastel)
  static const Color secondary = Color(0xFFA8D5E2); // Pastel Sky Blue
  static const Color accent = Color(0xFFB0E0E6); // Powder Blue

  // Màu nền - Light (pastel cream/white)
  static const Color background = Color(0xFFFFFBF7); // Warm Cream White
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFEF9F5); // Soft Cream

  // Màu nền - Dark
  static const Color backgroundDark = Color(0xFF1A202C); // Gray 900
  static const Color surfaceDark = Color(0xFF2D3748); // Gray 800
  static const Color surfaceLightDark = Color(0xFF1A202C);

  // Màu text - Light
  static const Color textPrimary = Color(0xFF1A202C); // Gray 800
  static const Color textSecondary = Color(0xFF718096); // Gray 500
  static const Color textLight = Color(0xFFA0AEC0); // Gray 400

  // Màu text - Dark
  static const Color textPrimaryDark = Color(0xFFF7FAFC); // Gray 50
  static const Color textSecondaryDark = Color(0xFFCBD5E0); // Gray 300
  static const Color textLightDark = Color(0xFFA0AEC0); // Gray 400

  // Màu trạng thái
  static const Color success = Color(0xFF48BB78); // Green 500
  static const Color error = Color(0xFFF56565); // Red 500
  static const Color warning = Color(0xFFED8936); // Orange 500
  static const Color info = Color(0xFF4299E1); // Blue 500

  // Màu sale/discount
  static const Color sale = Color(0xFFE53E3E); // Red 600
  static const Color saleBackground = Color(0xFFFED7D7); // Red 100

  // Màu rating
  static const Color rating = Color(0xFFFFD700); // Gold

  // Màu button - Pastel Pink (giữ màu pastel cho buttons)
  static const Color buttonPrimary = Color(0xFFFFB6C1); // Pastel Pink
  static const Color buttonPrimaryLight = Color(0xFFFFC0CB); // Pink Light
  static const Color buttonPrimaryDark = Color(0xFFFF91A4); // Pink Dark
  static const Color buttonSecondary = Color(0xFFA8D5E2); // Pastel Blue (secondary)
  static const Color buttonDisabled = Color(0xFFFFE4E9); // Pink Disabled

  // Helper methods for theme-aware colors
  static Color getBackground(bool isDark) => isDark ? backgroundDark : background;
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surface;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color getTextLight(bool isDark) => isDark ? textLightDark : textLight;
}
