import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/datasources/remote/auth_remote_data_source.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/shipper_bottom_nav_bar.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../../core/theme/app_colors.dart';
import 'signup_page.dart';

class Sp {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
}

class Rad {
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, full = 100.0;
}

const Duration _kEntrance = Duration(milliseconds: 440);

/// Staggered entrance — fade + slideY (premium auth pattern, flutter_animate).
Widget _loginEntranceAt(Widget child, Duration delay) {
  return child
      .animate()
      .fadeIn(duration: _kEntrance, delay: delay, curve: Curves.easeOutCubic)
      .slideY(
        begin: 0.1,
        end: 0,
        duration: _kEntrance,
        delay: delay,
        curve: Curves.easeOutCubic,
      );
}

/// Đăng nhập — floating fields + entrance animation; accent `AppColors`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '575215795478-hm9np6bf9iiprt7p32t0506ppcqv07di.apps.googleusercontent.com',
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final LoginUseCase _loginUseCase;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  void _initializeDependencies() {
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _googleServerClientId,
    );

    final apiClient = ApiClient();
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
    final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
    _loginUseCase = LoginUseCase(repository: repository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final authResponse = await _loginUseCase(email, password);

        await TokenStorage.saveToken(
          token: authResponse.token,
          refreshToken: authResponse.refreshToken,
          expiresAt: authResponse.expiresAt,
        );

        await UserStorage.saveUser(
          userId: authResponse.user.userId,
          email: authResponse.user.email,
          fullName: authResponse.user.fullName,
          userRole: authResponse.user.userRole,
        );

        if (mounted) {
          ToastNotification.success(
            context,
            'Đăng nhập thành công! Xin chào ${authResponse.user.fullName}',
          );

          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted) {
            final userRole = authResponse.user.userRole;
            final homeWidget = (userRole == '3' || userRole == 'Shipper')
                ? const ShipperBottomNavBar()
                : const BottomNavBar();

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => homeWidget),
              (route) => false,
            );
          }
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không thể lấy Google idToken. Vui lòng thử lại.');
      }

      final authResponse = await _loginUseCase.loginWithGoogle(idToken);
      await _handleLoginSuccess(authResponse);
    } on PlatformException catch (error) {
      _handleGooglePlatformError(error);
    } catch (error) {
      _handleLoginError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGooglePlatformError(PlatformException error) {
    final details =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}'
            .toLowerCase();

    if (error.code == 'sign_in_failed' &&
        details.contains('apiexception: 10')) {
      _handleLoginError(
        Exception(
          'Google Sign-In chưa được cấu hình đúng cho Android (DEVELOPER_ERROR 10). '
          'Hãy tạo OAuth client Android với package com.example.pet_shop và SHA1 debug, '
          'sau đó chạy lại ứng dụng.',
        ),
      );
      return;
    }

    _handleLoginError(
      Exception(
        'Google Sign-In thất bại (${error.code}): ${error.message ?? ''}',
      ),
    );
  }

  Future<void> _handleLoginSuccess(AuthResponse authResponse) async {
    await TokenStorage.saveToken(
      token: authResponse.token,
      refreshToken: authResponse.refreshToken,
      expiresAt: authResponse.expiresAt,
    );

    await UserStorage.saveUser(
      userId: authResponse.user.userId,
      email: authResponse.user.email,
      fullName: authResponse.user.fullName,
    );

    if (!mounted) return;

    ToastNotification.success(
      context,
      'Đăng nhập thành công! Xin chào ${authResponse.user.fullName}',
    );

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const BottomNavBar()),
      (route) => false,
    );
  }

  void _handleLoginError(Object error) {
    final errorMsg = error.toString().replaceAll('Exception: ', '');

    setState(() {
      _errorMessage = errorMsg;
    });

    if (!mounted) return;

    ToastNotification.error(
      context,
      errorMsg,
      duration: const Duration(seconds: 4),
    );
  }

  static List<BoxShadow> get _fieldShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get _ctaShadow => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get _socialShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  Widget _floatingField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: _fieldShadow,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryVeryLight,
              AppColors.surface,
            ],
            stops: [0.0, 0.42],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minH = constraints.maxHeight;
              return RepaintBoundary(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Sp.lg,
                    Sp.xl,
                    Sp.lg,
                    Sp.lg + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _loginEntranceAt(
                                _buildHeaderBlock(),
                                Duration.zero,
                              ),
                              const SizedBox(height: Sp.xl + Sp.sm),
                              if (_errorMessage != null) ...[
                                KeyedSubtree(
                                  key: ValueKey(_errorMessage),
                                  child: _loginEntranceAt(
                                    _buildErrorBanner(),
                                    const Duration(milliseconds: 70),
                                  ),
                                ),
                                const SizedBox(height: Sp.md),
                              ],
                              _loginEntranceAt(
                                _floatingField(
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: _plainFieldDeco('Email'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Email không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const Duration(milliseconds: 120),
                              ),
                              const SizedBox(height: Sp.lg),
                              _loginEntranceAt(
                                _floatingField(
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration:
                                        _plainFieldDeco('Mật khẩu').copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 22,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePassword =
                                              !_obscurePassword);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu';
                                      }
                                      if (value.length < 6) {
                                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const Duration(milliseconds: 175),
                              ),
                              _loginEntranceAt(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryDark,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: Sp.xs,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    child: const Text('Quên mật khẩu?'),
                                  ),
                                ),
                                const Duration(milliseconds: 220),
                              ),
                              const SizedBox(height: Sp.sm),
                              _loginEntranceAt(
                                _buildPrimaryButton(),
                                const Duration(milliseconds: 265),
                              ),
                              const SizedBox(height: Sp.lg + Sp.xs),
                              _loginEntranceAt(
                                _buildSocialDivider(),
                                const Duration(milliseconds: 310),
                              ),
                              const SizedBox(height: Sp.lg),
                              _buildSocialRow(),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Sp.xl),
                            child: _loginEntranceAt(
                              _buildSignupFooter(),
                              const Duration(milliseconds: 420),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _plainFieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textLight,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      border: InputBorder.none,
      errorStyle: const TextStyle(fontSize: 12, height: 1.2),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Sp.lg,
        vertical: 18,
      ),
    );
  }

  Widget _buildHeaderBlock() {
    return Column(
      children: [
        _buildLogoMark(),
        const SizedBox(height: Sp.md),
        _buildBrandDots(),
        const SizedBox(height: Sp.sm),
        Text(
          'Pet Shop',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.primaryDark,
            height: 1.05,
          ),
        ),
        const SizedBox(height: Sp.xl),
        Text(
          'Đăng nhập tài khoản',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandDots() {
    final dots = [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < dots.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dots[i], shape: BoxShape.circle),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoMark() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Rad.xl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: _fieldShadow,
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(Sp.sm),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.pets_rounded,
              color: AppColors.primaryDark,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: _ctaShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(Rad.lg),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textLight.withValues(alpha: 0.28),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          child: Text(
            'Hoặc đăng nhập với',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.15,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textLight.withValues(alpha: 0.28),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _loginEntranceAt(
          _socialSquare(
            onTap: _isLoading ? null : _handleGoogleLogin,
            child: SvgPicture.asset(
              'assets/icon/google_icon.svg',
              width: 26,
              height: 26,
            ),
          ),
          const Duration(milliseconds: 350),
        ),
        _loginEntranceAt(
          _socialSquare(
            onTap: _isLoading ? null : () {},
            child: FaIcon(
              FontAwesomeIcons.facebookF,
              size: 22,
              color: Colors.blue.shade700,
            ),
          ),
          const Duration(milliseconds: 395),
        ),
        _loginEntranceAt(
          _socialSquare(
            onTap: _isLoading ? null : () {},
            child: FaIcon(
              FontAwesomeIcons.xTwitter,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const Duration(milliseconds: 440),
        ),
      ],
    );
  }

  Widget _socialSquare({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(Rad.md),
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.md),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rad.md),
            color: AppColors.surface,
            boxShadow: _socialShadow,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildSignupFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const SignUpPage()));
          },
          child: const Text(
            'Đăng ký',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Rad.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
