import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_response.dart';
import '../../data/datasources/remote/auth_remote_data_source.dart';
import '../../data/models/google_login_request_dto.dart';
import '../../data/models/login_request_dto.dart';
import '../../data/mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final request = LoginRequestDto(email: email, password: password);
      final response = await remoteDataSource.login(request);
      return AuthMapper.toEntity(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final request = GoogleLoginRequestDto(idToken: idToken);
      final response = await remoteDataSource.loginWithGoogle(request);
      return AuthMapper.toEntity(response);
    } catch (e) {
      rethrow;
    }
  }
}
