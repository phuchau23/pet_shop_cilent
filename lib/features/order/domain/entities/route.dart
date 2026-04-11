import 'package:latlong2/latlong.dart';

class Route {
  final double distance; // mét
  final int duration; // giây
  final List<LatLng> polyline; // Đường đi

  Route({
    required this.distance,
    required this.duration,
    required this.polyline,
  });

  /// Khoảng cách dạng km
  double get distanceKm => distance / 1000;

  /// Thời gian dạng phút
  int get durationMinutes => (duration / 60).round();

  /// Format khoảng cách: "5.2 km"
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${distance.toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Format thời gian: "15 phút"
  String get formattedDuration {
    if (durationMinutes < 1) {
      return '< 1 phút';
    }
    return '$durationMinutes phút';
  }
}
