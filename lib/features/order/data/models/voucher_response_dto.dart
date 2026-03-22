class VoucherResponseDto {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String discountType; // 'percentage' | 'fixed_amount'
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String? createdAt;

  VoucherResponseDto({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.usedCount,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.createdAt,
  });

  factory VoucherResponseDto.fromJson(Map<String, dynamic> json) {
    return VoucherResponseDto(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderAmount: json['minOrderAmount'] != null
          ? (json['minOrderAmount'] as num).toDouble()
          : null,
      maxDiscountAmount: json['maxDiscountAmount'] != null
          ? (json['maxDiscountAmount'] as num).toDouble()
          : null,
      usageLimit: (json['usageLimit'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String?,
    );
  }
}
