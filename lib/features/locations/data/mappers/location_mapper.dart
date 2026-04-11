import '../models/province_dto.dart';
import '../models/district_dto.dart';
import '../models/ward_dto.dart';
import '../../domain/entities/province.dart';
import '../../domain/entities/district.dart';
import '../../domain/entities/ward.dart';

class LocationMapper {
  static Province toProvinceEntity(ProvinceDto dto) {
    return Province(
      code: dto.code,
      name: dto.name,
      latitude: dto.latitude,
      longitude: dto.longitude,
    );
  }

  static List<Province> toProvinceEntityList(List<ProvinceDto> dtos) {
    return dtos.map((dto) => toProvinceEntity(dto)).toList();
  }

  static District toDistrictEntity(DistrictDto dto) {
    return District(
      code: dto.code,
      name: dto.name,
    );
  }

  static List<District> toDistrictEntityList(List<DistrictDto> dtos) {
    return dtos.map((dto) => toDistrictEntity(dto)).toList();
  }

  static Ward toWardEntity(WardDto dto) {
    return Ward(
      code: dto.code,
      name: dto.name,
    );
  }

  static List<Ward> toWardEntityList(List<WardDto> dtos) {
    return dtos.map((dto) => toWardEntity(dto)).toList();
  }
}
