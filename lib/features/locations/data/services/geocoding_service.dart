import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // Nominatim API của OpenStreetMap (miễn phí, không cần API key)
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Geocode địa chỉ để lấy tọa độ
  /// Returns null nếu không tìm thấy
  static Future<LatLng?> geocodeAddress({
    required String wardName,
    required String districtName,
    required String provinceName,
  }) async {
    try {
      // Tạo query string từ địa chỉ
      final query = '$wardName, $districtName, $provinceName, Vietnam';
      final encodedQuery = Uri.encodeComponent(query);
      
      final url = Uri.parse(
        '$_baseUrl/search?q=$encodedQuery&format=json&limit=1&addressdetails=1&countrycodes=vn',
      );
      
      print('🌍 Geocoding address: $query');
      print('🌍 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'PetShopApp/1.0', // Nominatim yêu cầu User-Agent
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          
          print('✅ Geocoding success: lat=$lat, lon=$lon');
          return LatLng(lat, lon);
        } else {
          print('⚠️ No results found for: $query');
          return null;
        }
      } else {
        print('❌ Geocoding failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      return null;
    }
  }
  
  /// Lấy boundary polygon của xã/phường từ Nominatim
  /// Returns list of LatLng points tạo thành polygon
  /// Note: Không phải tất cả xã/phường đều có boundary trong OSM
  /// Nếu không tìm thấy, sẽ return null để dùng fallback polygon
  static Future<List<LatLng>?> getBoundaryPolygon({
    required String wardName,
    required String districtName,
    required String provinceName,
  }) async {
    try {
      // Thử tìm boundary từ Nominatim reverse geocoding với polygon
      // Đầu tiên geocode để lấy tọa độ
      final coordinates = await geocodeAddress(
        wardName: wardName,
        districtName: districtName,
        provinceName: provinceName,
      );
      
      if (coordinates == null) {
        print('⚠️ Cannot geocode address for boundary');
        return null;
      }
      
      // Thử lấy boundary từ Overpass API với tọa độ
      return await _getBoundaryFromOverpass(
        coordinates.latitude,
        coordinates.longitude,
        wardName,
      );
    } catch (e) {
      print('❌ Boundary error: $e');
      return null;
    }
  }
  
  /// Lấy boundary từ Overpass API dựa trên tọa độ
  static Future<List<LatLng>?> _getBoundaryFromOverpass(
    double lat,
    double lon,
    String wardName,
  ) async {
    try {
      // Overpass API query: tìm administrative boundary gần nhất
      final query = '''
[out:json][timeout:25];
(
  way["boundary"="administrative"]["admin_level"="9"](around:5000,${lat},${lon});
  relation["boundary"="administrative"]["admin_level"="9"](around:5000,${lat},${lon});
);
out geom;
''';
      
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      
      print('🗺️ Fetching boundary from Overpass for: $wardName');
      
      final response = await http.post(
        url,
        body: query,
        headers: {
          'Content-Type': 'text/plain',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>?;
        
        if (elements == null || elements.isEmpty) {
          print('⚠️ No boundary data found from Overpass');
          return null;
        }
        
        // Tìm element có geometry (way hoặc relation)
        for (final element in elements) {
          final geometry = element['geometry'] as List<dynamic>?;
          if (geometry != null && geometry.isNotEmpty) {
            final List<LatLng> points = [];
            for (final point in geometry) {
              final pointLat = (point['lat'] as num).toDouble();
              final pointLon = (point['lon'] as num).toDouble();
              points.add(LatLng(pointLat, pointLon));
            }
            
            if (points.length >= 3) {
              print('✅ Found boundary with ${points.length} points');
              return points;
            }
          }
        }
      }
      
      print('⚠️ Could not extract boundary polygon from Overpass');
      return null;
    } catch (e) {
      print('❌ Overpass API error: $e');
      return null;
    }
  }
  
  /// Reverse geocode: Lấy địa chỉ từ tọa độ
  static Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=${coordinates.latitude}&lon=${coordinates.longitude}&format=json&addressdetails=1',
      );
      
      print('🌍 Reverse geocoding: lat=${coordinates.latitude}, lon=${coordinates.longitude}');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'PetShopApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        if (address != null) {
          // Tạo địa chỉ từ các thành phần
          final parts = <String>[];
          
          if (address['house_number'] != null) {
            parts.add(address['house_number'] as String);
          }
          if (address['road'] != null) {
            parts.add(address['road'] as String);
          }
          if (address['suburb'] != null || address['neighbourhood'] != null) {
            parts.add(address['suburb'] ?? address['neighbourhood'] as String);
          }
          
          if (parts.isNotEmpty) {
            final addressString = parts.join(', ');
            print('✅ Reverse geocoding success: $addressString');
            return addressString;
          }
        }
      }
      
      print('⚠️ No address found for coordinates');
      return null;
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return null;
    }
  }
  
  /// Geocode địa chỉ cụ thể (có số nhà, tên đường)
  static Future<LatLng?> geocodeSpecificAddress({
    required String specificAddress,
    required String wardName,
    required String districtName,
    required String provinceName,
  }) async {
    try {
      // Tạo query với địa chỉ cụ thể
      final query = '$specificAddress, $wardName, $districtName, $provinceName, Vietnam';
      final encodedQuery = Uri.encodeComponent(query);
      
      final url = Uri.parse(
        '$_baseUrl/search?q=$encodedQuery&format=json&limit=1&addressdetails=1&countrycodes=vn',
      );
      
      print('🌍 Geocoding specific address: $query');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'PetShopApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          
          print('✅ Geocoding specific address success: lat=$lat, lon=$lon');
          return LatLng(lat, lon);
        }
      }
      
      print('⚠️ No results found for specific address');
      return null;
    } catch (e) {
      print('❌ Geocoding specific address error: $e');
      return null;
    }
  }
  
  /// Fallback: Tạo polygon đơn giản xung quanh điểm (nếu không lấy được boundary)
  static List<LatLng> createSimplePolygon(LatLng center, {double radius = 0.01}) {
    return [
      LatLng(center.latitude + radius, center.longitude - radius),
      LatLng(center.latitude + radius, center.longitude + radius),
      LatLng(center.latitude - radius, center.longitude + radius),
      LatLng(center.latitude - radius, center.longitude - radius),
      LatLng(center.latitude + radius, center.longitude - radius),
    ];
  }
}
