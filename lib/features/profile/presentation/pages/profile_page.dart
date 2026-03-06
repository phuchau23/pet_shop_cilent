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
      // Hiển thị loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authDataSource = AuthRemoteDataSourceImpl(apiClient: ApiClient());
      final profile = await authDataSource.getProfile();

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Hiển thị dialog với thông tin profile
      if (mounted) {
        _showProfileDialog(profile);
      }
    } catch (e) {
      print('❌ Error loading profile from API: $e');

      // Đóng loading dialog nếu còn mở
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Hiển thị lỗi
      if (mounted) {
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
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài Khoản')),
      body: _isLoadingFromStorage
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserInfoFromStorage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryVeryLight, Colors.white],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userName ?? _userEmail ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_userPhone != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _userPhone!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Menu Items
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _ProfileMenuItem(
                            icon: Icons.person_outline,
                            title: 'Thông Tin Cá Nhân',
                            onTap: _loadProfileFromAPI,
                          ),
                          _ProfileMenuItem(
                            icon: Icons.location_on_outlined,
                            title: 'Địa Chỉ Giao Hàng',
                            onTap: () {
                              // TODO: Navigate to addresses
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.receipt_long_outlined,
                            title: 'Đơn Hàng Của Tôi',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyOrdersPage(),
                                ),
                              );
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.favorite_outline,
                            title: 'Sản Phẩm Yêu Thích',
                            onTap: () {
                              // TODO: Navigate to favorites
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Thông Báo',
                            onTap: () {
                              // TODO: Navigate to notifications
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Cài Đặt',
                            onTap: () {
                              // TODO: Navigate to settings
                            },
                          ),
                          const Divider(height: 32),
                          _ProfileMenuItem(
                            icon: Icons.logout,
                            title: 'Đăng Xuất',
                            titleColor: AppColors.error,
                            onTap: () async {
                              // Hiển thị loading dialog
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              // 1. Lấy userId trước khi xóa (để xóa cart)
                              int? userId;
                              try {
                                userId = await UserStorage.getUserId();
                              } catch (e) {
                                print('⚠️ Error getting userId: $e');
                              }

                              // 2. Gọi API logout để backend biết user đã logout
                              try {
                                final authDataSource = AuthRemoteDataSourceImpl(
                                  apiClient: ApiClient(),
                                );
                                await authDataSource.logout();
                              } catch (e) {
                                // Không cần xử lý error vì vẫn sẽ xóa local storage
                                print('⚠️ Logout API error: $e');
                              }

                              // 3. Xóa cart data và đóng Isar (nếu có userId)
                              if (userId != null) {
                                try {
                                  final cartRepository = CartRepositoryImpl();
                                  await cartRepository.clearCart(userId);
                                  print('🗑️ Cart cleared for user: $userId');
                                } catch (e) {
                                  print('⚠️ Error clearing cart: $e');
                                  // Không throw vì vẫn cần logout
                                }
                              }
                              
                              // 3.1. Đóng Isar instance
                              try {
                                await IsarService.close();
                                print('✅ Isar closed');
                              } catch (e) {
                                print('⚠️ Error closing Isar: $e');
                                // Không throw vì vẫn cần logout
                              }

                              // 4. Xóa tất cả token và user info từ local storage
                              try {
                                await TokenStorage.clearToken();
                                await UserStorage.clearUser();
                                print('✅ All data cleared');
                              } catch (e) {
                                print('⚠️ Error clearing storage: $e');
                                // Vẫn tiếp tục navigate về login
                              }

                              // 5. Đóng loading dialog và navigate về login
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pop(); // Đóng loading dialog
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.primary,
                size: 24,
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
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
