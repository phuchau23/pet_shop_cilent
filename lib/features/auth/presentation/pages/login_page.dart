import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/datasources/remote/auth_remote_data_source.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('Attempting login for: $email');
      final authResponse = await _loginUseCase(email, password);
      print('Login successful!');
      await _handleLoginSuccess(authResponse);
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

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('ℹ️ Google login cancelled by user');
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
    print('Token saved to storage');

    await UserStorage.saveUser(
      userId: authResponse.user.userId,
      email: authResponse.user.email,
      fullName: authResponse.user.fullName,
    );
    print('User info saved');

    if (!mounted) {
      return;
    }

    print('Navigating to BottomNavBar...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đăng nhập thành công! Xin chào ${authResponse.user.fullName}',
        ),
        backgroundColor: Colors.green,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const BottomNavBar()),
      (route) => false,
    );
    print('Navigation completed');
  }

  void _handleLoginError(Object error) {
    print('Login error: $error');
    final errorMsg = error.toString().replaceAll('Exception: ', '');

    setState(() {
      _errorMessage = errorMsg;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onboarding.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade50.withOpacity(0.85),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Đăng Nhập',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Để tiếp tục với chúng tôi, bạn phải đăng nhập',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Email Của Bạn',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade400,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
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
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal.shade400,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Đăng Nhập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Nếu bạn không có tài khoản, hãy tạo mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: SvgPicture.asset(
                              'assets/icon/google_icon.svg',
                              width: 44,
                              height: 44,
                            ),
                            onPressed: _handleGoogleLogin,
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            icon: const Icon(Icons.apple, size: 44),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            icon: Icon(
                              Icons.facebook,
                              color: Colors.blue.shade700,
                              size: 44,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
