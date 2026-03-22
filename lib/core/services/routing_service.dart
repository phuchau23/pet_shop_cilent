import 'package:dio/dio.dart';
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
}

class RoutingService {
  final Dio _dio;
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  RoutingService({Dio? dio}) : _dio = dio ?? Dio();

  /// Tính đường đi giữa 2 điểm
  Future<Route?> calculateRoute(
    LatLng start,
    LatLng end, {
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      // OSRM format: {lng},{lat};{lng},{lat}
      final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      
      final response = await _dio.get(
        '$_osrmBaseUrl/route/v1/$profile/$coordinates',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      if (response.data['code'] == 'Ok' && 
          response.data['routes'] != null && 
          (response.data['routes'] as List).isNotEmpty) {
        final route = response.data['routes'][0];
        final distance = (route['distance'] as num).toDouble(); // mét
        final duration = (route['duration'] as num).toInt(); // giây
        
        // Parse GeoJSON geometry
        final geometry = route['geometry'];
        List<LatLng> polyline = [];
        
        if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
          final coordinates = geometry['coordinates'] as List;
          for (var coord in coordinates) {
            if (coord is List && coord.length >= 2) {
              // GeoJSON format: [lng, lat]
              polyline.add(LatLng(coord[1] as double, coord[0] as double));
            }
          }
        }

        return Route(
          distance: distance,
          duration: duration,
          polyline: polyline,
        );
      }

      return null;
    } catch (e) {
      print('❌ Error calculating route: $e');
      return null;
    }
  }
}
