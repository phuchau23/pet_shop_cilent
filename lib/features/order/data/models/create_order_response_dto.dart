class CreateOrderResponseDto {
  final int id;
  final String customerName;
  final String customerPhone;
  final String? fullAddress;
  final int? estimatedDeliveryMinutes;
  final double? estimatedDistanceMeters;
  final String status; // 'pending' | 'confirmed' | 'shipping' | 'delivered' | 'cancelled'
  final double totalPrice; // Tổng tiền sản phẩm
  final double? voucherDiscount; // Số tiền giảm từ voucher
  final double finalAmount; // ⭐ Tổng tiền cuối cùng (sau giảm giá) - từ BE
  final String? voucherCode;
  final String? note;
  final String createdAt;
  final List<OrderItemResponseDto> items;

  CreateOrderResponseDto({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.fullAddress,
    this.estimatedDeliveryMinutes,
    this.estimatedDistanceMeters,
    required this.status,
    required this.totalPrice,
    this.voucherDiscount,
    required this.finalAmount,
    this.voucherCode,
    this.note,
    required this.createdAt,
    required this.items,
  });

  factory CreateOrderResponseDto.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponseDto(
      id: json['id'] as int,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      fullAddress: json['fullAddress'] as String?,
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] as int?,
      estimatedDistanceMeters: json['estimatedDistanceMeters'] != null
          ? (json['estimatedDistanceMeters'] as num).toDouble()
          : null,
      status: json['status'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      voucherDiscount: json['voucherDiscount'] != null
          ? (json['voucherDiscount'] as num).toDouble()
          : null,
      finalAmount: (json['finalAmount'] as num).toDouble(),
      voucherCode: json['voucherCode'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItemResponseDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItemResponseDto {
  final int id;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItemResponseDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemResponseDto.fromJson(Map<String, dynamic> json) {
    return OrderItemResponseDto(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
