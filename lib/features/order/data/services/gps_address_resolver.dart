import 'package:latlong2/latlong.dart';

import '../../../locations/data/services/geocoding_service.dart';
import '../../../locations/domain/entities/district.dart';
import '../../../locations/domain/entities/province.dart';
import '../../../locations/domain/entities/ward.dart';
import '../../domain/entities/address_result.dart';

/// Ghép GPS + Nominatim + danh mục tỉnh/huyện/xã (API) thành [AddressResult].
class GpsAddressResolver {
  GpsAddressResolver._();

  static bool _looseContains(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    final na = a.toLowerCase().trim();
    final nb = b.toLowerCase().trim();
    return na.contains(nb) || nb.contains(na);
  }

  static String _stripWardPrefix(String name) {
    return name
        .replaceFirst(RegExp(r'^(Phường|Xã|Thị trấn)\s+', caseSensitive: false), '')
        .trim();
  }

  static Province? _pickProvince(List<Province> provinces, OsmAddressParts d) {
    final hints = [d.state, d.city, d.county]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final p in provinces) {
      for (final h in hints) {
        if (_looseContains(p.name, h)) return p;
      }
      for (final h in hints) {
        if (h.contains('Hồ Chí Minh') && p.name.contains('Hồ Chí Minh')) {
          return p;
        }
        if (h.contains('Ho Chi Minh') && p.name.contains('Hồ Chí Minh')) {
          return p;
        }
      }
    }
    return null;
  }

  static District? _pickDistrict(
    List<District> districts,
    OsmAddressParts d,
  ) {
    final hints = [d.city, d.cityDistrict, d.county, d.suburb, d.town]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final dist in districts) {
      for (final h in hints) {
        if (_looseContains(dist.name, h)) return dist;
      }
    }
    for (final dist in districts) {
      for (final h in hints) {
        if (h.contains('Thủ') && dist.name.contains('Thủ')) return dist;
      }
    }
    return null;
  }

  static Ward? _pickWard(List<Ward> wards, OsmAddressParts d) {
    final hints = [d.suburb, d.quarter, d.neighbourhood, d.cityDistrict]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final w in wards) {
      final short = _stripWardPrefix(w.name);
      for (final h in hints) {
        if (_looseContains(w.name, h) || _looseContains(short, h)) return w;
      }
    }
    return null;
  }

  static Future<AddressResult?> resolve({
    required double latitude,
    required double longitude,
    required List<Province> provinces,
    required Future<List<District>> Function(int provinceCode) loadDistricts,
    required Future<List<Ward>> Function(int districtCode) loadWards,
  }) async {
    final detail = await GeocodingService.reverseGeocodeDetail(
      LatLng(latitude, longitude),
    );
    if (detail == null) return null;

    final province = _pickProvince(provinces, detail);
    if (province == null) return null;

    final districts = await loadDistricts(province.code);
    if (districts.isEmpty) return null;

    final district = _pickDistrict(districts, detail);
    if (district == null) return null;

    final wards = await loadWards(district.code);
    if (wards.isEmpty) return null;

    final ward = _pickWard(wards, detail);
    if (ward == null) return null;

    final street = detail.streetLine;
    final fullAddress = street.isNotEmpty
        ? '$street, ${ward.name}, ${district.name}, ${province.name}'
        : '${ward.name}, ${district.name}, ${province.name}';

    return AddressResult(
      provinceName: province.name,
      districtName: district.name,
      wardName: ward.name,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
      provinceCode: province.code,
      districtCode: district.code,
      wardCode: ward.code,
      deliveryEstimate: null,
    );
  }
}
