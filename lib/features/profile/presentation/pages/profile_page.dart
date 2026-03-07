import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/profile_response_dto.dart';
import '../../../auth/data/datasources/remote/auth_remote_data_source.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../order/presentation/pages/my_orders_page.dart';
import '../../../cart/data/repositories/cart_repository.dart';
import '../../../../core/database/isar_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  bool _isLoadingFromStorage = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfoFromStorage();
  }

  Future<void> _loadUserInfoFromStorage() async {
    try {
      final fullName = await UserStorage.getUserFullName();
      final email = await UserStorage.getUserEmail();
      final phone = await UserStorage.getUserPhone();

      if (mounted) {
        setState(() {
          _userName = fullName;
          _userEmail = email;
          _userPhone = phone;
          _isLoadingFromStorage = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user info from storage: $e');
      if (mounted) {
        setState(() {
          _isLoadingFromStorage = false;
        });
      }
    }
  }

  Future<void> _loadProfileFromAPI() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authDataSource = AuthRemoteDataSourceImpl(apiClient: ApiClient());
      final profile = await authDataSource.getProfile();

      if (mounted) {
        Navigator.of(context).pop();
        _showProfileDialog(profile);
      }
    } catch (e) {
      print('❌ Error loading profile from API: $e');

      if (mounted) {
        Navigator.of(context).pop();
        String errorMessage = 'Không thể tải thông tin profile.';
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showProfileDialog(ProfileResponseDto profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông Tin Cá Nhân'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileInfoRow(
                'Họ và tên',
                profile.fullName ?? 'Chưa cập nhật',
              ),
              const SizedBox(height: 12),
              _buildProfileInfoRow('Email', profile.email),
              const SizedBox(height: 12),
              _buildProfileInfoRow(
                'Số điện thoại',
                profile.phoneNumber ?? 'Chưa cập nhật',
              ),
              const SizedBox(height: 12),
              _buildProfileInfoRow('Vai trò', profile.userRole),
              const SizedBox(height: 12),
              _buildProfileInfoRow('Trạng thái', profile.accountStatus),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tài Khoản',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.surface,
      ),
      body: _isLoadingFromStorage
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserInfoFromStorage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header - merged with AppBar background
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                      ),
                      child: Column(
                        children: [
                          // Avatar with subtle background
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Name
                          Text(
                            _userName ?? _userEmail ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // Email
                          if (_userEmail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _userEmail!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.3,
                                letterSpacing: 0.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          // Phone
                          if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryVeryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _userPhone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Menu Sections
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        children: [
                          // Account Section
                          _MenuSection(
                            title: 'Tài khoản',
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.person_outline_rounded,
                                title: 'Thông tin cá nhân',
                                onTap: _loadProfileFromAPI,
                              ),
                              _ProfileMenuItem(
                                icon: Icons.location_on_outlined,
                                title: 'Địa chỉ giao hàng',
                                onTap: () {
                                  // TODO: Navigate to addresses
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Orders Section
                          _MenuSection(
                            title: 'Đơn hàng',
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.receipt_long_outlined,
                                title: 'Đơn hàng của tôi',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyOrdersPage(),
                                    ),
                                  );
                                },
                              ),
                              _ProfileMenuItem(
                                icon: Icons.favorite_outline_rounded,
                                title: 'Sản phẩm yêu thích',
                                onTap: () {
                                  // TODO: Navigate to favorites
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Preferences Section
                          _MenuSection(
                            title: 'Tùy chọn',
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.notifications_outlined,
                                title: 'Thông báo',
                                onTap: () {
                                  // TODO: Navigate to notifications
                                },
                              ),
                              _ProfileMenuItem(
                                icon: Icons.settings_outlined,
                                title: 'Cài đặt',
                                onTap: () {
                                  // TODO: Navigate to settings
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Logout Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.textLight.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: _ProfileMenuItem(
                              icon: Icons.logout_rounded,
                              title: 'Đăng xuất',
                              titleColor: AppColors.error,
                              iconColor: AppColors.error,
                              onTap: () async {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                int? userId;
                                try {
                                  userId = await UserStorage.getUserId();
                                } catch (e) {
                                  print('⚠️ Error getting userId: $e');
                                }

                                try {
                                  final authDataSource = AuthRemoteDataSourceImpl(
                                    apiClient: ApiClient(),
                                  );
                                  await authDataSource.logout();
                                } catch (e) {
                                  print('⚠️ Logout API error: $e');
                                }

                                if (userId != null) {
                                  try {
                                    final cartRepository = CartRepositoryImpl();
                                    await cartRepository.clearCart(userId);
                                    print('🗑️ Cart cleared for user: $userId');
                                  } catch (e) {
                                    print('⚠️ Error clearing cart: $e');
                                  }
                                }

                                try {
                                  await IsarService.close();
                                  print('✅ Isar closed');
                                } catch (e) {
                                  print('⚠️ Error closing Isar: $e');
                                }

                                try {
                                  await TokenStorage.clearToken();
                                  await UserStorage.clearUser();
                                  print('✅ All data cleared');
                                } catch (e) {
                                  print('⚠️ Error clearing storage: $e');
                                }

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withOpacity(0.7),
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textLight.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(children: _buildChildrenWithDividers()),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: AppColors.textLight.withOpacity(0.08),
          ),
        );
      }
    }
    return result;
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = titleColor == AppColors.error;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary)
                      .withOpacity(isDestructive ? 0.1 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppColors.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight.withOpacity(0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
