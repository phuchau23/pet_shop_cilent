class WardDto {
  final int code;
  final String name;

  WardDto({
    required this.code,
    required this.name,
  });

  factory WardDto.fromJson(Map<String, dynamic> json) {
    return WardDto(
      code: json['code'] as int,
      name: json['name'] as String,
    );
  }
}
