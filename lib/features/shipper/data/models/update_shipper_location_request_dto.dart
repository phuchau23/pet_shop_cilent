class UpdateShipperLocationRequestDto {
  final double lat;
  final double lng;

  UpdateShipperLocationRequestDto({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
