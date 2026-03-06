class DistrictDto {
  final int code;
  final String name;

  DistrictDto({
    required this.code,
    required this.name,
  });

  factory DistrictDto.fromJson(Map<String, dynamic> json) {
    return DistrictDto(
      code: json['code'] as int,
      name: json['name'] as String,
    );
  }
}
