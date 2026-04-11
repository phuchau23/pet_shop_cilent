class Address {
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final String? fullAddress; // Kết hợp text + coordinates
  final String? wardName; // Phường/Xã
  final String? districtName; // Quận/Huyện
  final String? cityName; // Thành phố

  Address({
    this.addressText,
    this.latitude,
    this.longitude,
    this.fullAddress,
    this.wardName,
    this.districtName,
    this.cityName,
  });

  bool get isValid => latitude != null && longitude != null;

  Address copyWith({
    String? addressText,
    double? latitude,
    double? longitude,
    String? fullAddress,
    String? wardName,
    String? districtName,
    String? cityName,
  }) {
    return Address(
      addressText: addressText ?? this.addressText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fullAddress: fullAddress ?? this.fullAddress,
      wardName: wardName ?? this.wardName,
      districtName: districtName ?? this.districtName,
      cityName: cityName ?? this.cityName,
    );
  }
}
