import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

class CategoryIconMapper {
  /// Map category name với icon và color phù hợp nhất cho Pet Shop
  /// Dựa vào data API: Cat/Dog Food, Toys, Treats, Accessories
  static Map<String, dynamic> getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();

    // ========== CATEGORY MAPPING ==========

    // 🍽️ FOOD - Thức ăn (màu xanh lá - healthy, fresh)
    if (name.contains('food')) {
      if (name.contains('cat')) {
        return {
          'icon': Icons.restaurant_menu_rounded,
          'color': const Color(0xFF48BB78), // Green 500 - healthy food
        };
      } else if (name.contains('dog')) {
        return {
          'icon': Icons.restaurant_menu_rounded,
          'color': const Color(0xFF38A169), // Green 600 - healthy food
        };
      }
      return {
        'icon': Icons.restaurant_menu_rounded,
        'color': const Color(0xFF48BB78),
      };
    }

    // 🎮 TOYS - Đồ chơi (màu cam - fun, playful)
    if (name.contains('toy')) {
      if (name.contains('cat')) {
        return {
          'icon': Icons.toys_rounded,
          'color': const Color(0xFFED8936), // Orange 500 - playful
        };
      } else if (name.contains('dog')) {
        return {
          'icon': Icons.toys_rounded,
          'color': const Color(0xFFF6AD55), // Orange 400 - playful
        };
      }
      return {'icon': Icons.toys_rounded, 'color': const Color(0xFFED8936)};
    }

    // 🍪 TREATS - Bánh thưởng (màu hồng - sweet, treat)
    if (name.contains('treat')) {
      if (name.contains('cat')) {
        return {
          'icon': Icons.cake_rounded,
          'color': const Color(0xFFED64A6), // Pink 500 - sweet treat
        };
      } else if (name.contains('dog')) {
        return {
          'icon': Icons.cookie_rounded,
          'color': const Color(0xFFF687B3), // Pink 400 - sweet treat
        };
      }
      return {'icon': Icons.cake_rounded, 'color': const Color(0xFFED64A6)};
    }

    // 🎀 ACCESSORIES - Phụ kiện (màu teal/cyan - stylish, accessory)
    if (name.contains('accessor')) {
      if (name.contains('cat')) {
        return {
          'icon': Icons.checkroom_rounded,
          'color': AppColors.primary, // Teal 400 - stylish
        };
      } else if (name.contains('dog')) {
        return {
          'icon': Icons.checkroom_rounded,
          'color': AppColors.primaryDark, // Teal 500 - stylish
        };
      }
      return {'icon': Icons.checkroom_rounded, 'color': AppColors.primary};
    }

    // 🐱 CAT (generic)
    if (name.contains('cat')) {
      return {'icon': FontAwesomeIcons.cat, 'color': AppColors.primary};
    }

    // 🐶 DOG (generic)
    if (name.contains('dog')) {
      return {
        'icon': FontAwesomeIcons.dog,
        'color': const Color(0xFF38A169), // Green 600
      };
    }

    // 🐦 BIRD
    if (name.contains('bird')) {
      return {
        'icon': FontAwesomeIcons.dove,
        'color': const Color(0xFF4299E1), // Blue 500
      };
    }

    // 🐠 FISH
    if (name.contains('fish')) {
      return {
        'icon': FontAwesomeIcons.fish,
        'color': const Color(0xFF3182CE), // Blue 600
      };
    }

    // 🐹 SMALL PETS (hamster, rabbit, etc.)
    if (name.contains('hamster') ||
        name.contains('rabbit') ||
        name.contains('guinea')) {
      return {
        'icon': FontAwesomeIcons.paw,
        'color': const Color(0xFFED8936), // Orange 500
      };
    }

    // Default fallback
    return {'icon': Icons.category_rounded, 'color': AppColors.primary};
  }
}
