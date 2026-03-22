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
import 'settings_page.dart';

// Spacing constants - base 8px system
class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// Border radius constants
class _Rad {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 100.0;
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  bool _isLoadingFromStorage = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadUserInfoFromStorage();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileDetailSheet(profile: profile),
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
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoadingFromStorage
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserInfoFromStorage,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Profile Header
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                    // Menu Sections
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        _Sp.md,
                        _Sp.lg,
                        _Sp.md,
                        _Sp.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _AnimatedMenuSection(
                            title: 'Tài khoản',
                            delay: const Duration(milliseconds: 200),
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
                          const SizedBox(height: _Sp.lg),
                          _AnimatedMenuSection(
                            title: 'Đơn hàng',
                            delay: const Duration(milliseconds: 300),
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
                          const SizedBox(height: _Sp.lg),
                          _AnimatedMenuSection(
                            title: 'Tùy chọn',
                            delay: const Duration(milliseconds: 400),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: _Sp.lg),
                          _AnimatedLogoutButton(
                            delay: const Duration(milliseconds: 500),
                            onLogout: _handleLogout,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(_Sp.md, _Sp.lg, _Sp.md, _Sp.xl),
          decoration: const BoxDecoration(color: AppColors.surface),
          child: Column(
            children: [
              // Avatar with improved styling
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 16,
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
                  );
                },
              ),
              const SizedBox(height: _Sp.lg),
              // Name with better hierarchy
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
                const SizedBox(height: _Sp.sm),
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
              // Phone badge
              if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                const SizedBox(height: _Sp.md),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _Sp.md,
                            vertical: _Sp.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryVeryLight,
                            borderRadius: BorderRadius.circular(_Rad.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: _Sp.sm),
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
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int? userId;
    try {
      userId = await UserStorage.getUserId();
    } catch (e) {
      print('⚠️ Error getting userId: $e');
    }

    try {
      final authDataSource = AuthRemoteDataSourceImpl(apiClient: ApiClient());
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
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

class _AnimatedMenuSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final Duration delay;

  const _AnimatedMenuSection({
    required this.title,
    required this.children,
    required this.delay,
  });

  @override
  State<_AnimatedMenuSection> createState() => _AnimatedMenuSectionState();
}

class _AnimatedMenuSectionState extends State<_AnimatedMenuSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _MenuSection(title: widget.title, children: widget.children),
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
          padding: const EdgeInsets.only(left: _Sp.xs, bottom: _Sp.sm + _Sp.xs),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_Rad.lg),
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
            endIndent: _Sp.md,
            color: AppColors.textLight.withOpacity(0.08),
          ),
        );
      }
    }
    return result;
  }
}

class _ProfileDetailSheet extends StatefulWidget {
  final ProfileResponseDto profile;

  const _ProfileDetailSheet({required this.profile});

  @override
  State<_ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<_ProfileDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(_Rad.xl)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: _Sp.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(_Rad.full),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _Sp.md,
                    _Sp.lg,
                    _Sp.md,
                    _Sp.md,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: _Sp.md),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông Tin Cá Nhân',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: _Sp.xs),
                            Text(
                              'Chi tiết tài khoản của bạn',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Info items - Single container with list items
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _Sp.md,
                      0,
                      _Sp.md,
                      _Sp.xl,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(_Rad.lg),
                      ),
                      child: Column(
                        children: [
                          _AnimatedProfileInfoItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Họ và tên',
                            value: widget.profile.fullName ?? 'Chưa cập nhật',
                            iconColor: AppColors.primary,
                            showDivider: true,
                            delay: const Duration(milliseconds: 100),
                          ),
                          _AnimatedProfileInfoItem(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: widget.profile.email,
                            iconColor: AppColors.info,
                            showDivider: true,
                            delay: const Duration(milliseconds: 150),
                          ),
                          _AnimatedProfileInfoItem(
                            icon: Icons.phone_outlined,
                            label: 'Số điện thoại',
                            value:
                                widget.profile.phoneNumber ?? 'Chưa cập nhật',
                            iconColor: AppColors.success,
                            showDivider: true,
                            delay: const Duration(milliseconds: 200),
                          ),
                          _AnimatedProfileInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'Vai trò',
                            value: widget.profile.userRole,
                            iconColor: AppColors.warning,
                            showDivider: true,
                            delay: const Duration(milliseconds: 250),
                          ),
                          _AnimatedProfileInfoItem(
                            icon: Icons.verified_outlined,
                            label: 'Trạng thái',
                            value: widget.profile.accountStatus,
                            iconColor: AppColors.success,
                            showDivider: false,
                            delay: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProfileInfoItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool showDivider;
  final Duration delay;

  const _AnimatedProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.showDivider = false,
    required this.delay,
  });

  @override
  State<_AnimatedProfileInfoItem> createState() =>
      _AnimatedProfileInfoItemState();
}

class _AnimatedProfileInfoItemState extends State<_AnimatedProfileInfoItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _ProfileInfoItem(
          icon: widget.icon,
          label: widget.label,
          value: widget.value,
          iconColor: widget.iconColor,
          showDivider: widget.showDivider,
        ),
      ),
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool showDivider;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _Sp.md,
            vertical: _Sp.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: _Sp.md),
              // Label and value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: _Sp.xs),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: _Sp.md + 22 + _Sp.md, // icon width + icon size + gap
            endIndent: _Sp.md,
            color: AppColors.textLight.withOpacity(0.08),
          ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatefulWidget {
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
  State<_ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<_ProfileMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ?? AppColors.primary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(_Rad.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _Sp.md,
                vertical: _Sp.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_Rad.md),
                    ),
                    child: Icon(
                      widget.icon,
                      color: effectiveIconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: _Sp.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.titleColor ?? AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight.withOpacity(0.4),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoutButton extends StatefulWidget {
  final Duration delay;
  final VoidCallback onLogout;

  const _AnimatedLogoutButton({required this.delay, required this.onLogout});

  @override
  State<_AnimatedLogoutButton> createState() => _AnimatedLogoutButtonState();
}

class _AnimatedLogoutButtonState extends State<_AnimatedLogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_Rad.lg),
            border: Border.all(
              color: AppColors.textLight.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: _ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            titleColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: widget.onLogout,
          ),
        ),
      ),
    );
  }
}
