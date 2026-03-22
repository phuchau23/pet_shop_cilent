import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  final VoidCallback? onExitComplete;
  final bool shouldExit;

  const SplashPage({
    super.key,
    required this.onAnimationComplete,
    this.onExitComplete,
    this.shouldExit = false,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _exitController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _exitFadeAnimation;
  late Animation<double> _exitScaleAnimation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Entrance animation controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Exit animation controller (ngắn hơn, mượt hơn)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Logo scale animation với elastic effect
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Text fade animation (delay sau logo)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Background fade animation
    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    // Exit animations - fade out + scale down nhẹ
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isExiting) {
        widget.onExitComplete?.call();
      }
    });

    _entranceController.forward().then((_) {
      // Delay nhẹ trước khi trigger exit
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isExiting) {
          widget.onAnimationComplete();
        }
      });
    });
  }

  @override
  void didUpdateWidget(SplashPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger exit when parent signals
    if (widget.shouldExit && !oldWidget.shouldExit && !_isExiting) {
      _startExit();
    }
  }

  void _startExit() {
    if (!_isExiting && mounted) {
      setState(() {
        _isExiting = true;
      });
      _exitController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: FadeTransition(
        opacity: _isExiting
            ? _exitFadeAnimation
            : AlwaysStoppedAnimation(_backgroundFadeAnimation.value),
        child: ScaleTransition(
          scale: _isExiting
              ? _exitScaleAnimation
              : AlwaysStoppedAnimation(1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.backgroundDark,
                        AppColors.surfaceDark,
                      ]
                    : [
                        AppColors.background,
                        AppColors.primaryVeryLight,
                      ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo với scale + fade animation
                    FadeTransition(
                      opacity: _isExiting
                          ? _exitFadeAnimation
                          : _logoFadeAnimation,
                      child: ScaleTransition(
                        scale: _isExiting
                            ? _exitScaleAnimation
                            : _logoScaleAnimation,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(
                                  alpha: _isExiting
                                      ? _exitFadeAnimation.value * 0.22
                                      : 0.22,
                                ),
                                blurRadius: 36,
                                spreadRadius: 2,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.pets_rounded,
                                size: 88,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App name với fade animation
                    FadeTransition(
                      opacity: _isExiting
                          ? _exitFadeAnimation
                          : _textFadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Pet Shop',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextPrimary(isDark),
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chăm sóc thú cưng của bạn',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.getTextSecondary(isDark),
                              letterSpacing: 0.2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
