class UpdateShipperStatusRequestDto {
  final int shipperId;
  final String status; // "shipping" | "delivered"
  final double? lat; // required when status = "shipping"
  final double? lng; // required when status = "shipping"

  UpdateShipperStatusRequestDto({
    required this.shipperId,
    required this.status,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'shipperId': shipperId,
      'status': status,
    };
    if (lat != null) json['lat'] = lat;
    if (lng != null) json['lng'] = lng;
    return json;
  }
}
