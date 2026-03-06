class OrderListItemDto {
  final int id;
  final String status; // "pending" | "confirmed" | "shipping" | "delivered" | "cancelled"
  final String statusDisplayName;
  final double totalPrice;
  final double finalAmount;
  final String? voucherCode;
  final double? voucherDiscount;
  final String createdAt;
  final String? fullAddress;
  final List<OrderItemSummaryDto> items;

  OrderListItemDto({
    required this.id,
    required this.status,
    required this.statusDisplayName,
    required this.totalPrice,
    required this.finalAmount,
    this.voucherCode,
    this.voucherDiscount,
    required this.createdAt,
    this.fullAddress,
    required this.items,
  });

  factory OrderListItemDto.fromJson(Map<String, dynamic> json) {
    return OrderListItemDto(
      id: json['id'] as int,
      status: json['status'] as String,
      statusDisplayName: json['statusDisplayName'] as String? ?? json['status'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      voucherCode: json['voucherCode'] as String?,
      voucherDiscount: json['voucherDiscount'] != null
          ? (json['voucherDiscount'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] as String,
      fullAddress: json['fullAddress'] as String?,
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItemSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItemSummaryDto {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? productImage;

  OrderItemSummaryDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.productImage,
  });

  factory OrderItemSummaryDto.fromJson(Map<String, dynamic> json) {
    return OrderItemSummaryDto(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      productImage: json['productImage'] as String?,
    );
  }
}
