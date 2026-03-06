import '../../domain/repositories/location_repository.dart';
import '../../domain/entities/province.dart';
import '../../domain/entities/district.dart';
import '../../domain/entities/ward.dart';
import '../datasources/remote/location_remote_data_source.dart';
import '../mappers/location_mapper.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;

  LocationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Province>> getProvinces() async {
    try {
      final dtos = await remoteDataSource.getProvinces();
      return LocationMapper.toProvinceEntityList(dtos);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<District>> getDistricts(int provinceCode) async {
    try {
      final dtos = await remoteDataSource.getDistricts(provinceCode);
      return LocationMapper.toDistrictEntityList(dtos);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Ward>> getWards(int districtCode) async {
    try {
      final dtos = await remoteDataSource.getWards(districtCode);
      return LocationMapper.toWardEntityList(dtos);
    } catch (e) {
      rethrow;
    }
  }
}
