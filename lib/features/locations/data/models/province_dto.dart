class ProvinceDto {
  final int code;
  final String name;
  final double latitude;
  final double longitude;

  ProvinceDto({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory ProvinceDto.fromJson(Map<String, dynamic> json) {
    return ProvinceDto(
      code: json['code'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
