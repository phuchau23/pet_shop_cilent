import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/user_storage.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'core/widgets/shipper_bottom_nav_bar.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/presentation/pages/splash_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider.notifier).themeMode;
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Pet Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;
  bool _showSplash = true;
  bool _splashAnimationComplete = false;
  bool _readyToExit = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final loggedIn = await TokenStorage.isLoggedIn();
      String? userRole;
      if (loggedIn) {
        userRole = await UserStorage.getUserRole();
      }
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _userRole = userRole;
          _isLoading = false;
        });
        _tryNavigate();
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
          _isLoading = false;
        });
        _tryNavigate();
      }
    }
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _splashAnimationComplete = true;
      });
      _tryNavigate();
    }
  }

  void _onSplashExitComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  void _tryNavigate() {
    // Chỉ trigger exit animation khi cả splash animation và login check đều xong
    if (_splashAnimationComplete &&
        !_isLoading &&
        _showSplash &&
        !_readyToExit) {
      setState(() {
        _readyToExit = true;
      });
    }
  }

  Widget _getHomeWidget() {
    // Role 1 = Customer, Role 3 = Shipper
    if (_userRole == '3' || _userRole == 'Shipper') {
      return const ShipperBottomNavBar();
    } else {
      return const BottomNavBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return SplashPage(
        onAnimationComplete: _onSplashComplete,
        onExitComplete: _onSplashExitComplete,
        shouldExit: _readyToExit,
      );
    }

    // Navigate to home or login
    return _isLoggedIn ? _getHomeWidget() : const LoginPage();
  }
}
