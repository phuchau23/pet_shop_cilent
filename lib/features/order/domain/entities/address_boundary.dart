import 'package:latlong2/latlong.dart';

class AddressBoundary {
  final String wardName; // Tên Phường/Xã
  final List<LatLng> polygon; // Ranh giới của Phường/Xã
  final LatLng center; // Tâm của khu vực

  AddressBoundary({
    required this.wardName,
    required this.polygon,
    required this.center,
  });
}
