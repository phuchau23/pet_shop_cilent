import 'package:flutter/material.dart';
import '../../features/shipper/presentation/pages/shipper_orders_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../theme/app_colors.dart';

class ShipperBottomNavBar extends StatefulWidget {
  const ShipperBottomNavBar({super.key});

  @override
  State<ShipperBottomNavBar> createState() => _ShipperBottomNavBarState();
}

class _ShipperBottomNavBarState extends State<ShipperBottomNavBar> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    print('🚚 Initializing ShipperBottomNavBar...');
    _pages = [
      const ShipperOrdersPage(),
      const ProfilePage(),
    ];
    print('✅ Shipper pages initialized');
  }

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Đơn hàng',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryVeryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
