import '../entities/province.dart';
import '../entities/district.dart';
import '../entities/ward.dart';

abstract class LocationRepository {
  Future<List<Province>> getProvinces();
  Future<List<District>> getDistricts(int provinceCode);
  Future<List<Ward>> getWards(int districtCode);
}
