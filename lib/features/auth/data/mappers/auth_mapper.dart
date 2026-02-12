import '../models/login_response_dto.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';

class AuthMapper {
  static AuthResponse toEntity(LoginResponseDto dto) {
    return AuthResponse(
      token: dto.token,
      refreshToken: dto.refreshToken,
      expiresAt: dto.expiresAt,
      user: User(
        userId: dto.user.userId,
        email: dto.user.email,
        fullName: dto.user.fullName,
        userRole: dto.user.userRole,
      ),
    );
  }
}
