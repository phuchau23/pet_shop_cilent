import 'package:flutter/material.dart';
import '../../features/shipper/presentation/pages/shipper_orders_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../theme/app_colors.dart';

// Spacing constants
class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
}

class ShipperBottomNavBar extends StatefulWidget {
  const ShipperBottomNavBar({super.key});

  @override
  State<ShipperBottomNavBar> createState() => _ShipperBottomNavBarState();
}

class _ShipperBottomNavBarState extends State<ShipperBottomNavBar>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  late final List<Widget> _pages;
  late final List<_NavItemData> _navItems;

  @override
  void initState() {
    super.initState();
    print('🚚 Initializing ShipperBottomNavBar...');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pages = [
      const ShipperOrdersPage(),
      const ProfilePage(),
    ];

    _navItems = [
      _NavItemData(
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping_rounded,
        label: 'Đơn hàng',
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Cá nhân',
      ),
    ];
    
    print('✅ Shipper pages initialized');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    print('🚚 Building ShipperBottomNavBar, current index: $_currentIndex');
    return Scaffold(
      body: Builder(
        builder: (context) {
          try {
            return IndexedStack(index: _currentIndex, children: _pages);
          } catch (e, stackTrace) {
            print('❌ Error building page: $e');
            print('❌ Stack trace: $stackTrace');
            return const Center(
              child: Text('Error loading page. Please try again.'),
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          border: Border(
            top: BorderSide(
              color: AppColors.getTextLight(isDark).withOpacity(0.1),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: _Sp.md, vertical: _Sp.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(
                  _navItems[index],
                  index,
                  isDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItemData item, int index, bool isDark) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected && _animationController.isAnimating
                  ? _scaleAnimation.value
                  : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _Sp.xs,
                  vertical: _Sp.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getTextSecondary(isDark),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getTextSecondary(isDark),
                        height: 1.2,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
