class ShipperOrderResponseDto {
  final int id;
  final String customerName;
  final String customerPhone;
  final String fullAddress;
  final double shopLat;
  final double shopLng;
  final String shopName;
  final double? customerLat;
  final double? customerLng;
  final int? estimatedDeliveryMinutes;
  final int? estimatedDistanceMeters;
  final int? shipperId;
  final String status;
  final double? totalPrice;
  final double? voucherDiscount;
  final double? finalAmount;
  final String? voucherCode;
  final String? note;
  final double? deliveryFee;
  final String? paymentMethod;
  final String createdAt;
  final String updatedAt;
  final List<ShipperOrderItemDto> items;

  ShipperOrderResponseDto({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.fullAddress,
    required this.shopLat,
    required this.shopLng,
    required this.shopName,
    this.customerLat,
    this.customerLng,
    this.estimatedDeliveryMinutes,
    this.estimatedDistanceMeters,
    this.shipperId,
    required this.status,
    this.totalPrice,
    this.voucherDiscount,
    this.finalAmount,
    this.voucherCode,
    this.note,
    this.deliveryFee,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory ShipperOrderResponseDto.fromJson(Map<String, dynamic> json) {
    // Helper function để convert dynamic thành String an toàn
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    String safeStringRequired(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return ShipperOrderResponseDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerName: safeStringRequired(json['customerName']),
      customerPhone: safeStringRequired(json['customerPhone']),
      fullAddress: safeStringRequired(json['fullAddress']),
      shopLat: (json['shopLat'] as num?)?.toDouble() ?? 0.0,
      shopLng: (json['shopLng'] as num?)?.toDouble() ?? 0.0,
      shopName: safeStringRequired(json['shopName']),
      customerLat: (json['customerLat'] as num?)?.toDouble(),
      customerLng: (json['customerLng'] as num?)?.toDouble(),
      estimatedDeliveryMinutes: (json['estimatedDeliveryMinutes'] as num?)?.toInt(),
      estimatedDistanceMeters: (json['estimatedDistanceMeters'] as num?)?.toInt(),
      shipperId: (json['shipperId'] as num?)?.toInt(),
      status: safeStringRequired(json['status']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      voucherDiscount: (json['voucherDiscount'] as num?)?.toDouble(),
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      voucherCode: safeString(json['voucherCode']),
      note: safeString(json['note']),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      paymentMethod: safeString(json['paymentMethod']),
      createdAt: safeStringRequired(json['createdAt']),
      updatedAt: safeStringRequired(json['updatedAt']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ShipperOrderItemDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ShipperOrderItemDto {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double? discount;

  ShipperOrderItemDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.discount,
  });

  factory ShipperOrderItemDto.fromJson(Map<String, dynamic> json) {
    return ShipperOrderItemDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble(),
    );
  }
}
