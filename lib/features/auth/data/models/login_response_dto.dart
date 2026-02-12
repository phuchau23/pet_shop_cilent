class LoginResponseDto {
  final String token;
  final String refreshToken;
  final String expiresAt;
  final UserDto user;

  LoginResponseDto({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: json['expiresAt'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserDto {
  final int userId;
  final String email;
  final String fullName;
  final String userRole;

  UserDto({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.userRole,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      userId: json['userId'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      userRole: json['userRole'] as String,
    );
  }
}
