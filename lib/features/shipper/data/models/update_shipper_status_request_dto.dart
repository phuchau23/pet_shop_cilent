class UpdateShipperStatusRequestDto {
  final int shipperId;
  final String status; // "shipping" | "delivered"

  UpdateShipperStatusRequestDto({
    required this.shipperId,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'shipperId': shipperId,
      'status': status,
    };
  }
}
