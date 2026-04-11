import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/location_remote_data_source.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_provinces_usecase.dart';
import '../../domain/usecases/get_districts_usecase.dart';
import '../../domain/usecases/get_wards_usecase.dart';
import '../../domain/entities/province.dart';
import '../../domain/entities/district.dart';
import '../../domain/entities/ward.dart';
import '../../../../core/network/api_client.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Location Remote Data Source Provider
final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationRemoteDataSourceImpl(apiClient: apiClient);
});

// Location Repository Provider
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final remoteDataSource = ref.watch(locationRemoteDataSourceProvider);
  return LocationRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Cases Providers
final getProvincesUseCaseProvider = Provider<GetProvincesUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetProvincesUseCase(repository: repository);
});

final getDistrictsUseCaseProvider = Provider<GetDistrictsUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetDistrictsUseCase(repository: repository);
});

final getWardsUseCaseProvider = Provider<GetWardsUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetWardsUseCase(repository: repository);
});

// Provinces Provider
final provincesProvider = FutureProvider<List<Province>>((ref) async {
  final useCase = ref.watch(getProvincesUseCaseProvider);
  return await useCase.call();
});

// Districts Provider (family)
final districtsProvider = FutureProvider.family<List<District>, int>((ref, provinceCode) async {
  final useCase = ref.watch(getDistrictsUseCaseProvider);
  return await useCase.call(provinceCode);
});

// Wards Provider (family)
final wardsProvider = FutureProvider.family<List<Ward>, int>((ref, districtCode) async {
  final useCase = ref.watch(getWardsUseCaseProvider);
  return await useCase.call(districtCode);
});
