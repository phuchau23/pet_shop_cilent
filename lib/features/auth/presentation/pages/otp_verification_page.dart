import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_notification.dart';
import 'login_page.dart';

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

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  late final List<AnimationController> _otpAnimationControllers;

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  late AnimationController _heroController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _timerController;

  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _startResendTimer();
    // Auto focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[0].requestFocus();
    });
  }

  void _initializeAnimations() {
    // Initialize OTP animation controllers
    _otpAnimationControllers = List.generate(
      6,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

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

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    // Listen to focus changes
    for (int i = 0; i < 6; i++) {
      _otpFocusNodes[i].addListener(() {
        if (_otpFocusNodes[i].hasFocus) {
          _otpAnimationControllers[i].forward();
        } else {
          _otpAnimationControllers[i].reverse();
        }
      });
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _heroController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _formController.forward();
    });
  }

  void _startResendTimer() {
    _timerController.addListener(() {
      if (mounted) {
        setState(() {
          _resendCountdown = 60 - (_timerController.value * 60).round();
          if (_resendCountdown <= 0) {
            _resendCountdown = 0;
          }
        });
      }
    });
    _timerController.forward();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in _otpAnimationControllers) {
      controller.dispose();
    }
    _heroController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _onOTPChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        // Last field, verify OTP
        _otpFocusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _otpFocusNodes[index - 1].requestFocus();
    }
  }


  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement OTP verification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Navigate to login on success
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      ToastNotification.success(
        context,
        'Xác thực thành công!',
      );
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    // TODO: Implement resend OTP
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isResending = false;
        _resendCountdown = 60;
      });

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();

      // Restart timer
      _timerController.reset();
      _timerController.forward();

      ToastNotification.success(
        context,
        'Đã gửi lại mã OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: _buildHeroSection(),
            ),
            Expanded(
              flex: 3,
              child: _buildFormSection(),
            ),
          ],
        ),
      ),
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
                AppColors.primary,
                AppColors.secondary,
                AppColors.primaryLight,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              _buildAnimatedCircle(
                top: -80,
                right: -80,
                size: 200,
                delay: 0,
              ),
              _buildAnimatedCircle(
                bottom: 80,
                left: -40,
                size: 150,
                delay: 200,
              ),
              _buildAnimatedCircle(
                top: 120,
                left: 40,
                size: 100,
                delay: 400,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Sp.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
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
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.verified_outlined,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: Sp.lg),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Text(
                                'Xác thực OTP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
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
                      ),
                      const SizedBox(height: Sp.sm),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Text(
                                'Nhập mã OTP đã gửi đến\n${widget.email}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildAnimatedCircle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Positioned(
          top: top,
          right: right,
          bottom: bottom,
          left: left,
          child: Opacity(
            opacity: 0.15 * value,
            child: Transform.scale(
              scale: value,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
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
            padding: const EdgeInsets.all(Sp.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập mã OTP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: Sp.sm),
                Text(
                  'Vui lòng nhập 6 chữ số đã được gửi đến email của bạn',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Sp.xl),
                _buildOTPFields(),
                const SizedBox(height: Sp.xl),
                _buildVerifyButton(),
                const SizedBox(height: Sp.lg),
                _buildResendSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutBack,
          builder: (context, value, _) {
            return Transform.scale(
              scale: 0.7 + (0.3 * value),
              child: Opacity(
                opacity: value,
                child: SizedBox(
                  width: 50,
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _otpAnimationControllers[index],
                    builder: (context, __) {
                      final focusValue = _otpAnimationControllers[index].value;
                      final borderColor = Color.lerp(
                        AppColors.textLight.withOpacity(0.3),
                        AppColors.primary,
                        focusValue,
                      )!;

                      return TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
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
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        onChanged: (value) => _onOTPChanged(index, value),
                        onTap: () {
                          _otpFocusNodes[index].requestFocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        if (!_isLoading) {
          _verifyOTP();
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
            onPressed: _isLoading ? null : _verifyOTP,
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
                    'Xác thực',
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

  Widget _buildResendSection() {
    return Column(
      children: [
        if (_resendCountdown > 0)
          Text(
            'Gửi lại mã sau ${_resendCountdown}s',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          )
        else
          TextButton(
            onPressed: _isResending ? null : _resendOTP,
            child: _isResending
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Text(
                    'Gửi lại mã OTP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
      ],
    );
  }
}
