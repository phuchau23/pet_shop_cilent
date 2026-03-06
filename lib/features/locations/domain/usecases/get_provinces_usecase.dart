import '../entities/province.dart';
import '../repositories/location_repository.dart';

class GetProvincesUseCase {
  final LocationRepository repository;

  GetProvincesUseCase({required this.repository});

  Future<List<Province>> call() async {
    return await repository.getProvinces();
  }
}
