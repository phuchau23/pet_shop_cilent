import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class AddressBoundary {
  final String wardName;
  final List<LatLng> polygon;
  final LatLng center;

  AddressBoundary({
    required this.wardName,
    required this.polygon,
    required this.center,
  });
}

class GeocodingService {
  final Dio _dio;
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  GeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  /// Lấy boundary polygon của Tỉnh/Thành phố
  Future<AddressBoundary?> getProvinceBoundary(String provinceName) async {
    try {
      final query = '$provinceName, Vietnam';
      
      final response = await _dio.get(
        '$_nominatimBaseUrl/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'polygon_geojson': '1',
          'limit': '1',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'PetShopApp/1.0',
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        
        // Parse GeoJSON polygon
        if (result['geojson'] != null) {
          final geojson = result['geojson'];
          final coordinates = geojson['coordinates'];
          
          List<LatLng> polygon = [];
          if (geojson['type'] == 'Polygon' && coordinates is List) {
            // Lấy outer ring (coordinates[0])
            final outerRing = coordinates[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                // GeoJSON format: [lng, lat]
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          } else if (geojson['type'] == 'MultiPolygon' && coordinates is List) {
            // Lấy polygon lớn nhất
            final firstPolygon = coordinates[0] as List;
            final outerRing = firstPolygon[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          }

          if (polygon.isNotEmpty) {
            // Tính center point
            double sumLat = 0, sumLng = 0;
            for (var point in polygon) {
              sumLat += point.latitude;
              sumLng += point.longitude;
            }
            final center = LatLng(
              sumLat / polygon.length,
              sumLng / polygon.length,
            );

            return AddressBoundary(
              wardName: provinceName,
              polygon: polygon,
              center: center,
            );
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting province boundary: $e');
      return null;
    }
  }

  /// Lấy boundary polygon của Phường/Xã
  Future<AddressBoundary?> getWardBoundary(String wardName, {String? city}) async {
    try {
      final query = city != null ? '$wardName, $city, Vietnam' : '$wardName, Vietnam';
      
      final response = await _dio.get(
        '$_nominatimBaseUrl/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'polygon_geojson': '1',
          'limit': '1',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'PetShopApp/1.0', // Nominatim yêu cầu User-Agent
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        
        // Parse GeoJSON polygon
        if (result['geojson'] != null) {
          final geojson = result['geojson'];
          final coordinates = geojson['coordinates'];
          
          List<LatLng> polygon = [];
          if (geojson['type'] == 'Polygon' && coordinates is List) {
            // Lấy outer ring (coordinates[0])
            final outerRing = coordinates[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                // GeoJSON format: [lng, lat]
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          } else if (geojson['type'] == 'MultiPolygon' && coordinates is List) {
            // Lấy polygon đầu tiên
            final firstPolygon = coordinates[0] as List;
            final outerRing = firstPolygon[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          }

          if (polygon.isNotEmpty) {
            // Tính center point
            double sumLat = 0, sumLng = 0;
            for (var point in polygon) {
              sumLat += point.latitude;
              sumLng += point.longitude;
            }
            final center = LatLng(
              sumLat / polygon.length,
              sumLng / polygon.length,
            );

            return AddressBoundary(
              wardName: wardName,
              polygon: polygon,
              center: center,
            );
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting ward boundary: $e');
      return null;
    }
  }

  /// Reverse geocoding: lat/lng → address
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '$_nominatimBaseUrl/reverse',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'PetShopApp/1.0',
          },
        ),
      );

      if (response.data['display_name'] != null) {
        return response.data['display_name'] as String;
      }

      return null;
    } catch (e) {
      print('❌ Error reverse geocoding: $e');
      return null;
    }
  }

  /// Lấy boundary polygon của Xã/Phường
  Future<List<LatLng>?> getWardBoundaryPolygon({
    required String wardName,
    required String districtName,
    required String provinceName,
  }) async {
    try {
      final query = '$wardName, $districtName, $provinceName, Vietnam';
      
      final response = await _dio.get(
        '$_nominatimBaseUrl/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'polygon_geojson': '1',
          'limit': '1',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'PetShopApp/1.0',
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        
        if (result['geojson'] != null) {
          final geojson = result['geojson'];
          final coordinates = geojson['coordinates'];
          
          List<LatLng> polygon = [];
          if (geojson['type'] == 'Polygon' && coordinates is List) {
            final outerRing = coordinates[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          } else if (geojson['type'] == 'MultiPolygon' && coordinates is List) {
            final firstPolygon = coordinates[0] as List;
            final outerRing = firstPolygon[0] as List;
            for (var coord in outerRing) {
              if (coord is List && coord.length >= 2) {
                polygon.add(LatLng(coord[1] as double, coord[0] as double));
              }
            }
          }

          return polygon.isNotEmpty ? polygon : null;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting ward boundary polygon: $e');
      return null;
    }
  }

  /// Tạo polygon đơn giản xung quanh điểm (fallback)
  static List<LatLng> createSimplePolygon(LatLng center, {double radius = 0.01}) {
    return [
      LatLng(center.latitude + radius, center.longitude - radius),
      LatLng(center.latitude + radius, center.longitude + radius),
      LatLng(center.latitude - radius, center.longitude + radius),
      LatLng(center.latitude - radius, center.longitude - radius),
      LatLng(center.latitude + radius, center.longitude - radius),
    ];
  }

  /// Forward geocoding: address → lat/lng
  Future<LatLng?> forwardGeocode(String address) async {
    try {
      final response = await _dio.get(
        '$_nominatimBaseUrl/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'PetShopApp/1.0',
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        final lat = double.parse(result['lat'] as String);
        final lng = double.parse(result['lon'] as String);
        return LatLng(lat, lng);
      }

      return null;
    } catch (e) {
      print('❌ Error forward geocoding: $e');
      return null;
    }
  }
}
