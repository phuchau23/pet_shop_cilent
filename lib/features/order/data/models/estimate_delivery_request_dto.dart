class EstimateDeliveryRequestDto {
  final double customerLat;
  final double customerLng;
  final double? orderTotal; // Optional: để tính free delivery

  EstimateDeliveryRequestDto({
    required this.customerLat,
    required this.customerLng,
    this.orderTotal,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customerLat': customerLat,
      'customerLng': customerLng,
    };
    if (orderTotal != null) {
      json['orderTotal'] = orderTotal!;
    }
    return json;
  }
}
