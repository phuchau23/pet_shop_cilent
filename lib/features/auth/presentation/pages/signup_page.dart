import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_colors.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';

// Spacing constants
class Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// Border radius constants
class Rad {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 100.0;
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '575215795478-hm9np6bf9iiprt7p32t0506ppcqv07di.apps.googleusercontent.com',
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _fullNameFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final GoogleSignIn _googleSignIn;

  // Animation controllers
  late AnimationController _heroController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _emailFocusController;
  late AnimationController _passwordFocusController;
  late AnimationController _confirmPasswordFocusController;
  late AnimationController _fullNameFocusController;
  late AnimationController _socialController;
  late AnimationController _shapeController;

  // Animations
  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;
  late Animation<double> _socialOpacity;
  late Animation<double> _shapeRotation;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeDependencies() {
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _googleServerClientId,
    );
  }

  void _initializeAnimations() {
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: Curves.easeOutCubic,
      ),
    );
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );

    _socialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _socialOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _socialController,
        curve: Curves.easeOut,
      ),
    );

    _shapeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _shapeRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shapeController,
        curve: Curves.linear,
      ),
    );

    _fullNameFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _emailFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _passwordFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _confirmPasswordFocusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fullNameFocusNode.addListener(_onFullNameFocusChange);
        _emailFocusNode.addListener(_onEmailFocusChange);
        _passwordFocusNode.addListener(_onPasswordFocusChange);
        _confirmPasswordFocusNode.addListener(_onConfirmPasswordFocusChange);
      }
    });
  }

  void _onFullNameFocusChange() {
    if (_fullNameFocusNode.hasFocus) {
      _fullNameFocusController.forward();
    } else {
      _fullNameFocusController.reverse();
    }
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      _emailFocusController.forward();
    } else {
      _emailFocusController.reverse();
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      _passwordFocusController.forward();
    } else {
      _passwordFocusController.reverse();
    }
  }

  void _onConfirmPasswordFocusChange() {
    if (_confirmPasswordFocusNode.hasFocus) {
      _confirmPasswordFocusController.forward();
    } else {
      _confirmPasswordFocusController.reverse();
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _heroController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _formController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _socialController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _fullNameFocusNode.removeListener(_onFullNameFocusChange);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _confirmPasswordFocusNode.removeListener(_onConfirmPasswordFocusChange);
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _heroController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _fullNameFocusController.dispose();
    _emailFocusController.dispose();
    _passwordFocusController.dispose();
    _confirmPasswordFocusController.dispose();
    _socialController.dispose();
    _shapeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // TODO: Implement sign up logic
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Navigate to OTP verification
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
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

      // TODO: Implement Google sign up
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required AnimationController focusController,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: focusController,
      builder: (context, child) {
        final focusValue = focusController.value;
        final iconColor = Color.lerp(
          AppColors.textSecondary,
          AppColors.primary,
          focusValue,
        )!;
        final borderColor = Color.lerp(
          AppColors.textLight.withOpacity(0.3),
          AppColors.primary,
          focusValue,
        )!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: Sp.sm),
            Transform.scale(
              scale: 1.0 + (0.01 * focusValue),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                obscureText: obscureText,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(icon, size: 20, color: iconColor),
                  suffixIcon: suffixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Rad.md),
                    borderSide: BorderSide(
                      color: AppColors.textLight.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Rad.md),
                    borderSide: BorderSide(
                      color: borderColor,
                      width: 1.5 + (0.5 * focusValue),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Rad.md),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Rad.md),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Rad.md),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 2.5,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Sp.md,
                    vertical: Sp.md,
                  ),
                ),
                validator: validator,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Container(
              padding: const EdgeInsets.all(Sp.md),
              margin: const EdgeInsets.only(bottom: Sp.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Rad.md),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        if (!_isLoading) {
          _handleSignUp();
        }
      },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Rad.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rad.md),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.textLight.withOpacity(0.3 * value),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.md),
                child: Text(
                  'Hoặc',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.textLight.withOpacity(0.3 * value),
                  thickness: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialButtons() {
    return FadeTransition(
      opacity: _socialOpacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSocialButton(
            icon: SvgPicture.asset(
              'assets/icon/google_icon.svg',
              width: 24,
              height: 24,
            ),
            onPressed: _isLoading ? null : _handleGoogleSignUp,
            delay: 0,
          ),
          const SizedBox(width: Sp.md),
          _buildSocialButton(
            icon: Icon(
              Icons.apple,
              size: 24,
              color: AppColors.textPrimary,
            ),
            onPressed: _isLoading ? null : () {},
            delay: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback? onPressed,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Rad.md),
                border: Border.all(
                  color: AppColors.textLight.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(Rad.md),
                  child: Center(child: icon),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroOpacity,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary,
                AppColors.primary,
                AppColors.primaryLight,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              _buildAnimatedShapes(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.xl,
                    vertical: Sp.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCustomLogo(),
                      const SizedBox(height: Sp.md),
                      _buildAnimatedTitle(),
                      const SizedBox(height: Sp.xs),
                      _buildAnimatedSubtitle(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedShapes() {
    return AnimatedBuilder(
      animation: _shapeRotation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Transform.rotate(
                angle: -_shapeRotation.value * 2 * 3.14159,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -50,
              child: Transform.rotate(
                angle: _shapeRotation.value * 2 * 3.14159,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150,
              right: 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: 30,
              child: Transform.rotate(
                angle: -_shapeRotation.value * 3.14159,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.secondary,
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.person_add_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    right: 25,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Text(
              'Tạo tài khoản mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
              child: Text(
                'Tham gia cùng chúng tôi ngay hôm nay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.3,
                ),
              ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection() {
    return SlideTransition(
      position: _formSlide,
      child: FadeTransition(
        opacity: _formOpacity,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Rad.xl),
              topRight: Radius.circular(Rad.xl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.xl,
              vertical: Sp.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: Sp.xs),
                Row(
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.lg),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) _buildErrorMessage(),
                      if (_errorMessage != null) const SizedBox(height: Sp.md),
                      _buildTextField(
                        controller: _fullNameController,
                        focusNode: _fullNameFocusNode,
                        focusController: _fullNameFocusController,
                        label: 'Họ và tên',
                        hint: 'Nhập họ và tên của bạn',
                        icon: Icons.person_outlined,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sp.md),
                      _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        focusController: _emailFocusController,
                        label: 'Email',
                        hint: 'Nhập email của bạn',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: Sp.md),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        focusController: _passwordFocusController,
                        label: 'Mật khẩu',
                        hint: 'Nhập mật khẩu của bạn',
                        icon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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
                      const SizedBox(height: Sp.md),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        focusController: _confirmPasswordFocusController,
                        label: 'Xác nhận mật khẩu',
                        hint: 'Nhập lại mật khẩu',
                        icon: Icons.lock_outlined,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sp.md),
                      _buildSignUpButton(),
                      const SizedBox(height: Sp.lg),
                      _buildDivider(),
                      const SizedBox(height: Sp.md),
                      _buildSocialButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: _buildHeroSection(),
            ),
            Expanded(
              flex: 2,
              child: _buildFormSection(),
            ),
          ],
        ),
      ),
    );
  }
}
