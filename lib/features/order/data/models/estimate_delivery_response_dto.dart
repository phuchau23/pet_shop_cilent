class EstimateDeliveryResponseDto {
  final double shopLat;
  final double shopLng;
  final String shopName;
  final double customerLat;
  final double customerLng;
  final int estimatedDeliveryMinutes;
  final double estimatedDistanceMeters;
  final double estimatedDistanceKm;
  final double deliveryFee; // ⭐ Phí ship từ BE
  final List<List<double>> routeCoordinates;

  EstimateDeliveryResponseDto({
    required this.shopLat,
    required this.shopLng,
    required this.shopName,
    required this.customerLat,
    required this.customerLng,
    required this.estimatedDeliveryMinutes,
    required this.estimatedDistanceMeters,
    required this.estimatedDistanceKm,
    required this.deliveryFee,
    required this.routeCoordinates,
  });

  factory EstimateDeliveryResponseDto.fromJson(Map<String, dynamic> json) {
    return EstimateDeliveryResponseDto(
      shopLat: (json['shopLat'] as num).toDouble(),
      shopLng: (json['shopLng'] as num).toDouble(),
      shopName: json['shopName'] as String,
      customerLat: (json['customerLat'] as num).toDouble(),
      customerLng: (json['customerLng'] as num).toDouble(),
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] as int,
      estimatedDistanceMeters: (json['estimatedDistanceMeters'] as num).toDouble(),
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      routeCoordinates: (json['routeCoordinates'] as List? ?? [])
          .map((coord) => (coord as List).map((e) => (e as num).toDouble()).toList())
          .toList(),
    );
  }
}
