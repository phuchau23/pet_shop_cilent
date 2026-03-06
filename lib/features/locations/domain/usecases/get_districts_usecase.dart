import '../entities/district.dart';
import '../repositories/location_repository.dart';

class GetDistrictsUseCase {
  final LocationRepository repository;

  GetDistrictsUseCase({required this.repository});

  Future<List<District>> call(int provinceCode) async {
    return await repository.getDistricts(provinceCode);
  }
}
