class ValidateVoucherRequestDto {
  final String code;
  final double orderAmount;

  ValidateVoucherRequestDto({
    required this.code,
    required this.orderAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code.trim().toUpperCase(),
      'orderAmount': orderAmount,
    };
  }
}
