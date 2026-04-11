class VoucherDto {
  const VoucherDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  /// `percentage` | `fixed_amount`
  final String discountType;
  final num discountValue;
  final int? minOrderAmount;
  final int? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  factory VoucherDto.fromJson(Map<String, dynamic> json) {
    return VoucherDto(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'percentage',
      discountValue: json['discountValue'] as num? ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toInt(),
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toInt(),
      usageLimit: (json['usageLimit'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isPercentage => discountType.toLowerCase() == 'percentage';
}
