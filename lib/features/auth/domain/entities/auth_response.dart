import 'user.dart';

class AuthResponse {
  final String token;
  final String refreshToken;
  final String expiresAt;
  final User user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });
}
