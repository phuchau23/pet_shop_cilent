import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/user_storage.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'core/widgets/shipper_bottom_nav_bar.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
          _isLoading = false;
        });
      }
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? _getHomeWidget() : const LoginPage();
  }
}
