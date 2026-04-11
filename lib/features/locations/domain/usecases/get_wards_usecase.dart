import '../entities/ward.dart';
import '../repositories/location_repository.dart';

class GetWardsUseCase {
  final LocationRepository repository;

  GetWardsUseCase({required this.repository});

  Future<List<Ward>> call(int districtCode) async {
    return await repository.getWards(districtCode);
  }
}
