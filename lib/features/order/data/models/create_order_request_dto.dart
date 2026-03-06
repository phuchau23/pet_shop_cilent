class CreateOrderRequestDto {
  final CustomerDto customer;
  final DeliveryAddressDto deliveryAddress;
  final List<OrderItemDto> items;
  final double totalPrice;
  final String? voucherCode;
  final String? note;
  final int? paymentMethod; // 1 = COD

  CreateOrderRequestDto({
    required this.customer,
    required this.deliveryAddress,
    required this.items,
    required this.totalPrice,
    this.voucherCode,
    this.note,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customer': customer.toJson(),
      'deliveryAddress': deliveryAddress.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalPrice': totalPrice,
    };
    
    if (voucherCode != null && voucherCode!.isNotEmpty) {
      json['voucherCode'] = voucherCode;
    }
    
    if (note != null && note!.isNotEmpty) {
      json['note'] = note;
    }
    
    if (paymentMethod != null) {
      json['paymentMethod'] = paymentMethod;
    }
    
    return json;
  }
}

class CustomerDto {
  final String name;
  final String phone;

  CustomerDto({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class DeliveryAddressDto {
  final String addressDetail;
  final int? wardCode;
  final int? districtCode;
  final int? provinceCode;
  final String? fullAddress;
  final double? lat;
  final double? lng;

  DeliveryAddressDto({
    required this.addressDetail,
    this.wardCode,
    this.districtCode,
    this.provinceCode,
    this.fullAddress,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'addressDetail': addressDetail,
    };
    
    if (wardCode != null) json['wardCode'] = wardCode;
    if (districtCode != null) json['districtCode'] = districtCode;
    if (provinceCode != null) json['provinceCode'] = provinceCode;
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      json['fullAddress'] = fullAddress;
    }
    if (lat != null) json['lat'] = lat;
    if (lng != null) json['lng'] = lng;
    
    return json;
  }
}

class OrderItemDto {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}
