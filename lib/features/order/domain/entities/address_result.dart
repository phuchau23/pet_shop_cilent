import '../../data/models/estimate_delivery_response_dto.dart';

class AddressResult {
  final String provinceName;
  final String districtName;
  final String wardName;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final int provinceCode;
  final int districtCode;
  final int wardCode;
  final EstimateDeliveryResponseDto? deliveryEstimate;

  AddressResult({
    required this.provinceName,
    required this.districtName,
    required this.wardName,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.provinceCode,
    required this.districtCode,
    required this.wardCode,
    this.deliveryEstimate,
  });
}
