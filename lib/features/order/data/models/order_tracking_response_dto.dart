class OrderTrackingResponseDto {
  final int orderId;
  final String currentStatus; // "pending" | "confirmed" | "shipping" | "delivered" | "cancelled"
  final String statusDisplayName;
  final String statusDescription;
  final int? shipperId;
  final String? shipperName;
  final double? shipperCurrentLat;
  final double? shipperCurrentLng;
  final String? shipperLocationUpdatedAt;
  final double? shopLat;
  final double? shopLng;
  final double? customerLat;
  final double? customerLng;
  final String createdAt;
  final String updatedAt;
  final List<StatusTimelineItemDto> timeline;

  OrderTrackingResponseDto({
    required this.orderId,
    required this.currentStatus,
    required this.statusDisplayName,
    required this.statusDescription,
    this.shipperId,
    this.shipperName,
    this.shipperCurrentLat,
    this.shipperCurrentLng,
    this.shipperLocationUpdatedAt,
    this.shopLat,
    this.shopLng,
    this.customerLat,
    this.customerLng,
    required this.createdAt,
    required this.updatedAt,
    required this.timeline,
  });

  factory OrderTrackingResponseDto.fromJson(Map<String, dynamic> json) {
    return OrderTrackingResponseDto(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      currentStatus: json['currentStatus'] as String? ?? '',
      statusDisplayName: json['statusDisplayName'] as String? ?? '',
      statusDescription: json['statusDescription'] as String? ?? '',
      shipperId: (json['shipperId'] as num?)?.toInt(),
      shipperName: json['shipperName'] as String?,
      shipperCurrentLat: (json['shipperCurrentLat'] as num?)?.toDouble(),
      shipperCurrentLng: (json['shipperCurrentLng'] as num?)?.toDouble(),
      shipperLocationUpdatedAt: json['shipperLocationUpdatedAt'] as String?,
      shopLat: (json['shopLat'] as num?)?.toDouble(),
      shopLng: (json['shopLng'] as num?)?.toDouble(),
      customerLat: (json['customerLat'] as num?)?.toDouble(),
      customerLng: (json['customerLng'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((item) => StatusTimelineItemDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StatusTimelineItemDto {
  final String status;
  final String statusDisplayName;
  final String description;
  final String timestamp;
  final bool isCompleted;
  final bool isCurrent;

  StatusTimelineItemDto({
    required this.status,
    required this.statusDisplayName,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
  });

  factory StatusTimelineItemDto.fromJson(Map<String, dynamic> json) {
    return StatusTimelineItemDto(
      status: json['status'] as String,
      statusDisplayName: json['statusDisplayName'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] as String,
      isCompleted: json['isCompleted'] as bool,
      isCurrent: json['isCurrent'] as bool,
    );
  }
}
