import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../locations/domain/entities/province.dart';
import '../../../locations/domain/entities/district.dart';
import '../../../locations/domain/entities/ward.dart';
import '../../../locations/data/services/geocoding_service.dart' as LocationGeocoding;
import '../../../../core/services/geocoding_service.dart' as CoreGeocoding;
// ignore: unused_import
import '../../../locations/domain/usecases/get_provinces_usecase.dart';
// ignore: unused_import
import '../../../locations/domain/usecases/get_districts_usecase.dart';
// ignore: unused_import
import '../../../locations/domain/usecases/get_wards_usecase.dart';
import '../../data/models/estimate_delivery_request_dto.dart';
import '../../data/models/estimate_delivery_response_dto.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import '../../domain/entities/address_result.dart';

class AddressSelectionPage extends ConsumerStatefulWidget {
  final AddressResult? initialAddress;
  
  const AddressSelectionPage({
    super.key,
    this.initialAddress,
  });

  @override
  ConsumerState<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends ConsumerState<AddressSelectionPage> {
  final TextEditingController _specificAddressController = TextEditingController();
  final MapController _mapController = MapController();
  
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  
  // Lưu code để restore (tránh lỗi object instance)
  int? _restoreProvinceCode;
  int? _restoreDistrictCode;
  int? _restoreWardCode;
  
  // Tọa độ và boundary
  LatLng? _wardCoordinates;
  LatLng? _selectedCoordinates; // Tọa độ đã chọn trên map
  List<LatLng>? _boundaryPolygon; // Boundary của xã/phường
  List<LatLng>? _provinceBoundaryPolygon; // Boundary của tỉnh
  bool _isLoadingGeocode = false;
  bool _isLoadingReverseGeocode = false;
  String? _selectedAddressFromMap;
  
  // Delivery estimate (chỉ lưu, không hiển thị route trong trang này)
  EstimateDeliveryResponseDto? _deliveryEstimate;
  bool _isLoadingEstimate = false;

  @override
  void initState() {
    super.initState();
    // Nếu có địa chỉ ban đầu, khôi phục lại
    if (widget.initialAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreAddress(widget.initialAddress!);
      });
    }
  }
  
  Future<void> _restoreAddress(AddressResult address) async {
    try {
      // Lưu code để restore sau khi data load
      setState(() {
        _restoreProvinceCode = address.provinceCode;
        _restoreDistrictCode = address.districtCode;
        _restoreWardCode = address.wardCode;
      });
      
      // Khôi phục địa chỉ cụ thể từ fullAddress
      String specificAddress = address.fullAddress;
      // Loại bỏ phần xã, quận, tỉnh
      specificAddress = specificAddress
          .replaceAll(', ${address.wardName}', '')
          .replaceAll(', ${address.districtName}', '')
          .replaceAll(', ${address.provinceName}', '')
          .trim();
      
      if (specificAddress.isNotEmpty && 
          specificAddress != address.wardName &&
          specificAddress != address.districtName &&
          specificAddress != address.provinceName) {
        _specificAddressController.text = specificAddress;
      }
      
      // Set tọa độ đã chọn
      setState(() {
        _selectedCoordinates = LatLng(address.latitude, address.longitude);
      });
      
      // Di chuyển map đến vị trí đã chọn (sau một delay nhỏ để map đã render)
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.move(
          LatLng(address.latitude, address.longitude),
          16.0,
        );
      });
    } catch (e) {
      print('❌ Error restoring address: $e');
    }
  }
  
  // Helper method để restore province từ list
  void _restoreProvinceFromList(List<Province> provinces) {
    if (_restoreProvinceCode != null && _selectedProvince == null) {
      try {
        final province = provinces.firstWhere(
          (p) => p.code == _restoreProvinceCode,
        );
        setState(() {
          _selectedProvince = province;
        });
      } catch (e) {
        print('❌ Province not found: $_restoreProvinceCode');
      }
    }
  }
  
  // Helper method để restore district từ list
  void _restoreDistrictFromList(List<District> districts) {
    if (_restoreDistrictCode != null && _selectedDistrict == null && _selectedProvince != null) {
      try {
        final district = districts.firstWhere(
          (d) => d.code == _restoreDistrictCode,
        );
        setState(() {
          _selectedDistrict = district;
        });
      } catch (e) {
        print('❌ District not found: $_restoreDistrictCode');
      }
    }
  }
  
  // Helper method để restore ward từ list
  void _restoreWardFromList(List<Ward> wards) {
    if (_restoreWardCode != null && _selectedWard == null && _selectedDistrict != null) {
      try {
        final ward = wards.firstWhere(
          (w) => w.code == _restoreWardCode,
        );
        setState(() {
          _selectedWard = ward;
        });
        // Geocode lại để load boundary
        _geocodeWard();
      } catch (e) {
        print('❌ Ward not found: $_restoreWardCode');
      }
    }
  }
  
  @override
  void dispose() {
    _specificAddressController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  Future<void> _geocodeSpecificAddress() async {
    if (_specificAddressController.text.trim().isEmpty) {
      return;
    }
    
    if (_selectedProvince == null || 
        _selectedDistrict == null || 
        _selectedWard == null) {
      return;
    }
    
    setState(() {
      _isLoadingGeocode = true;
    });
    
    try {
      final coordinates = await LocationGeocoding.GeocodingService.geocodeSpecificAddress(
        specificAddress: _specificAddressController.text.trim(),
        wardName: _selectedWard!.name,
        districtName: _selectedDistrict!.name,
        provinceName: _selectedProvince!.name,
      );
      
      if (coordinates != null) {
        setState(() {
          _selectedCoordinates = coordinates;
        });
        
        // Di chuyển map đến vị trí mới
        _mapController.move(coordinates, 16.0);
        
        // Reverse geocode để lấy địa chỉ chính xác
        _reverseGeocode(coordinates);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy địa chỉ. Vui lòng thử lại hoặc chọn trên bản đồ.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      print('❌ Geocode specific address error: $e');
    } finally {
      setState(() {
        _isLoadingGeocode = false;
      });
    }
  }
  
  Future<void> _reverseGeocode(LatLng coordinates) async {
    setState(() {
      _isLoadingReverseGeocode = true;
    });
    
    try {
      final address = await LocationGeocoding.GeocodingService.reverseGeocode(coordinates);
      if (address != null) {
        setState(() {
          _selectedAddressFromMap = address;
        });
        // Cập nhật text field với địa chỉ từ reverse geocode
        if (_specificAddressController.text.isEmpty) {
          _specificAddressController.text = address;
        }
      }
    } catch (e) {
      print('❌ Reverse geocode error: $e');
    } finally {
      setState(() {
        _isLoadingReverseGeocode = false;
      });
    }
  }
  
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedCoordinates = point;
    });
    
    // Reverse geocode để lấy địa chỉ
    _reverseGeocode(point);
  }

  /// Load ranh giới tỉnh
  Future<void> _loadProvinceBoundary(String provinceName) async {
    setState(() {
      _isLoadingGeocode = true;
      _provinceBoundaryPolygon = null;
    });

    try {
      final geocodingService = CoreGeocoding.GeocodingService();
      final boundary = await geocodingService.getProvinceBoundary(provinceName);
      
      if (boundary != null && boundary.polygon.isNotEmpty) {
        setState(() {
          _provinceBoundaryPolygon = boundary.polygon;
        });
        
        // Fit map để hiển thị toàn bộ tỉnh
        final bounds = LatLngBounds.fromPoints(boundary.polygon);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('❌ Error loading province boundary: $e');
    } finally {
      setState(() {
        _isLoadingGeocode = false;
      });
    }
  }

  Future<void> _geocodeWard() async {
    if (_selectedProvince == null || 
        _selectedDistrict == null || 
        _selectedWard == null) {
      return;
    }

    setState(() {
      _isLoadingGeocode = true;
      _wardCoordinates = null;
      _boundaryPolygon = null;
    });

    try {
      // Geocode để lấy tọa độ của xã/phường
      final coordinates = await LocationGeocoding.GeocodingService.geocodeAddress(
        wardName: _selectedWard!.name,
        districtName: _selectedDistrict!.name,
        provinceName: _selectedProvince!.name,
      );

      if (coordinates != null) {
        setState(() {
          _wardCoordinates = coordinates;
        });

        // Lấy boundary polygon từ OSM
        final geocodingService = CoreGeocoding.GeocodingService();
        final boundary = await geocodingService.getWardBoundaryPolygon(
          wardName: _selectedWard!.name,
          districtName: _selectedDistrict!.name,
          provinceName: _selectedProvince!.name,
        );

        if (boundary != null && boundary.isNotEmpty) {
          setState(() {
            _boundaryPolygon = boundary;
          });
          
          // Fit map để hiển thị toàn bộ xã/phường
          final bounds = LatLngBounds.fromPoints(boundary);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              );
            }
          });
        } else {
          // Fallback: tạo polygon đơn giản
          setState(() {
            _boundaryPolygon = CoreGeocoding.GeocodingService.createSimplePolygon(coordinates);
          });
        }
      } else {
        // Nếu không geocode được, dùng tọa độ của tỉnh và tạo polygon đơn giản
        setState(() {
          _wardCoordinates = LatLng(
            _selectedProvince!.latitude,
            _selectedProvince!.longitude,
          );
          _boundaryPolygon = CoreGeocoding.GeocodingService.createSimplePolygon(_wardCoordinates!);
        });
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      // Fallback: dùng tọa độ của tỉnh
      setState(() {
        _wardCoordinates = LatLng(
          _selectedProvince!.latitude,
          _selectedProvince!.longitude,
        );
        _boundaryPolygon = CoreGeocoding.GeocodingService.createSimplePolygon(_wardCoordinates!);
      });
    } finally {
      setState(() {
        _isLoadingGeocode = false;
      });
    }
  }

  Future<void> _estimateDelivery(double lat, double lng) async {
    setState(() {
      _isLoadingEstimate = true;
      _deliveryEstimate = null;
    });

    try {
      final dataSource = OrderRemoteDataSourceImpl(
        apiClient: ApiClient(),
      );
      
      final request = EstimateDeliveryRequestDto(
        customerLat: lat,
        customerLng: lng,
      );
      
      final response = await dataSource.estimateDelivery(request);
      
      setState(() {
        _deliveryEstimate = response;
        // Không hiển thị route trong trang này, chỉ lưu để trả về
      });
    } catch (e) {
      print('❌ Estimate delivery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoadingEstimate = false;
      });
    }
  }

  void _onConfirm() async {
    if (_selectedProvince == null || 
        _selectedDistrict == null || 
        _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện và Phường/Xã'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Sử dụng tọa độ đã chọn trên map nếu có, nếu không thì dùng tọa độ xã/phường
    final lat = _selectedCoordinates?.latitude ?? 
                _wardCoordinates?.latitude ?? 
                _selectedProvince!.latitude;
    final lng = _selectedCoordinates?.longitude ?? 
                _wardCoordinates?.longitude ?? 
                _selectedProvince!.longitude;
    
    // Call estimate delivery
    await _estimateDelivery(lat, lng);
    
    // Nếu có estimate, hiển thị dialog xác nhận
    if (_deliveryEstimate != null && mounted) {
      _showConfirmDialog(lat, lng);
    } else if (mounted) {
      // Nếu không có estimate, vẫn cho phép xác nhận
      _confirmAddress(lat, lng);
    }
  }
  
  void _confirmAddress(double lat, double lng) {
    // Tạo địa chỉ đầy đủ
    String fullAddress = '';
    if (_specificAddressController.text.trim().isNotEmpty) {
      fullAddress = '${_specificAddressController.text.trim()}, ';
    }
    fullAddress += '${_selectedWard!.name}, ${_selectedDistrict!.name}, ${_selectedProvince!.name}';
    
    final result = AddressResult(
      provinceName: _selectedProvince!.name,
      districtName: _selectedDistrict!.name,
      wardName: _selectedWard!.name,
      fullAddress: fullAddress,
      latitude: lat,
      longitude: lng,
      provinceCode: _selectedProvince!.code,
      districtCode: _selectedDistrict!.code,
      wardCode: _selectedWard!.code,
      deliveryEstimate: _deliveryEstimate,
    );
    Navigator.pop(context, result);
  }
  
  void _showConfirmDialog(double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Xác nhận địa chỉ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có muốn xác nhận địa chỉ này không?',
              style: TextStyle(fontSize: 14),
            ),
            if (_deliveryEstimate != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.store, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _deliveryEstimate!.shopName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Khoảng cách:'),
                  Text(
                    '${_deliveryEstimate!.estimatedDistanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thời gian dự kiến:'),
                  Text(
                    '${_deliveryEstimate!.estimatedDeliveryMinutes} phút',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              _confirmAddress(lat, lng);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final districtsAsync = _selectedProvince != null
        ? ref.watch(districtsProvider(_selectedProvince!.code))
        : null;
    final wardsAsync = _selectedDistrict != null
        ? ref.watch(wardsProvider(_selectedDistrict!.code))
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Chọn địa chỉ nhận hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Province Dropdown
                  provincesAsync.when(
                    data: (provinces) {
                      // Restore province nếu có
                      if (_restoreProvinceCode != null && _selectedProvince == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _restoreProvinceFromList(provinces);
                        });
                      }
                      return _buildDropdown<Province>(
                        label: 'Tỉnh/Thành phố',
                        value: _selectedProvince,
                        items: provinces,
                        onChanged: (province) {
                          setState(() {
                            _selectedProvince = province;
                            _selectedDistrict = null;
                            _selectedWard = null;
                            _restoreDistrictCode = null;
                            _restoreWardCode = null;
                            _boundaryPolygon = null;
                            _provinceBoundaryPolygon = null;
                          });
                          // Vẽ ranh giới tỉnh
                          if (province != null) {
                            _loadProvinceBoundary(province.name);
                          }
                        },
                        getLabel: (province) => province.name,
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Lỗi: ${error.toString()}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // District Dropdown
                  if (_selectedProvince != null)
                    districtsAsync != null
                        ? districtsAsync.when(
                            data: (districts) {
                              // Restore district nếu có
                              if (_restoreDistrictCode != null && _selectedDistrict == null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _restoreDistrictFromList(districts);
                                });
                              }
                              return _buildDropdown<District>(
                                label: 'Quận/Huyện',
                                value: _selectedDistrict,
                                items: districts,
                                onChanged: (district) {
                                  setState(() {
                                    _selectedDistrict = district;
                                    _selectedWard = null;
                                    _restoreWardCode = null;
                                  });
                                },
                                getLabel: (district) => district.name,
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, stack) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Lỗi: ${error.toString()}',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  // Ward Dropdown
                  if (_selectedDistrict != null)
                    wardsAsync != null
                        ? wardsAsync.when(
                            data: (wards) {
                              // Restore ward nếu có
                              if (_restoreWardCode != null && _selectedWard == null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _restoreWardFromList(wards);
                                });
                              }
                              return _buildDropdown<Ward>(
                                label: 'Phường/Xã',
                                value: _selectedWard,
                                items: wards,
                                onChanged: (ward) {
                                  setState(() {
                                    _selectedWard = ward;
                                  });
                                  // Geocode khi chọn xã/phường
                                  _geocodeWard();
                                },
                                getLabel: (ward) => ward.name,
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, stack) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Lỗi: ${error.toString()}',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  // Ô nhập địa chỉ cụ thể
                  if (_selectedWard != null) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa chỉ cụ thể (Số nhà, tên đường)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _specificAddressController,
                                decoration: InputDecoration(
                                  hintText: 'Ví dụ: 123 Đường ABC',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (_) => _geocodeSpecificAddress(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _isLoadingGeocode ? null : _geocodeSpecificAddress,
                              icon: _isLoadingGeocode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                      color: AppColors.primary,
                                    ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryVeryLight,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoadingReverseGeocode) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Đang lấy địa chỉ...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ] else if (_selectedAddressFromMap != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryVeryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedAddressFromMap!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  // Map với viền khu vực (render ngay khi có tỉnh)
                  if (_selectedProvince != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Vị trí trên bản đồ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isLoadingGeocode) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVeryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chạm vào bản đồ hoặc kéo marker để chọn vị trí chính xác',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textLight, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedCoordinates ?? 
                                          _wardCoordinates ?? 
                                          LatLng(_selectedProvince!.latitude, _selectedProvince!.longitude),
                            initialZoom: _selectedCoordinates != null ? 16.0 : 
                                        (_wardCoordinates != null ? 13.0 : 11.0),
                            onTap: _onMapTap,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            // Light theme tile layer (CartoDB Positron - màu sáng như Google Maps)
                            TileLayer(
                              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.petshop.app',
                              maxZoom: 19,
                            ),
                            // Polygon layer để vẽ ranh giới tỉnh
                            if (_provinceBoundaryPolygon != null)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _provinceBoundaryPolygon!,
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderColor: AppColors.primary,
                                    borderStrokeWidth: 2.0,
                                    isFilled: true,
                                  ),
                                ],
                              ),
                            // Polygon layer để vẽ ranh giới xã/phường
                            if (_boundaryPolygon != null)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _boundaryPolygon!,
                                    color: const Color(0xFFFF9800).withOpacity(0.2),
                                    borderColor: const Color(0xFFFF9800),
                                    borderStrokeWidth: 2.5,
                                    isFilled: true,
                                  ),
                                ],
                              ),
                            // Marker layer - Shop và Customer
                            MarkerLayer(
                              markers: [
                                // Shop marker (nếu có estimate)
                                if (_deliveryEstimate != null)
                                  Marker(
                                    point: LatLng(_deliveryEstimate!.shopLat, _deliveryEstimate!.shopLng),
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.store,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                // Customer marker (ưu tiên) - Có thể kéo bằng cách di chuyển map
                                if (_selectedCoordinates != null)
                                  Marker(
                                    point: _selectedCoordinates!,
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                else if (_wardCoordinates != null)
                                  Marker(
                                    point: _wardCoordinates!,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_on,
                                      color: AppColors.primary.withOpacity(0.7),
                                      size: 40,
                                    ),
                                  )
                                else if (_selectedProvince != null)
                                  Marker(
                                    point: LatLng(_selectedProvince!.latitude, _selectedProvince!.longitude),
                                    width: 35,
                                    height: 35,
                                    child: Icon(
                                      Icons.location_on,
                                      color: AppColors.primary.withOpacity(0.5),
                                      size: 35,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Hiển thị thông tin estimate delivery
                  if (_deliveryEstimate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVeryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thông tin giao hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cửa hàng:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _deliveryEstimate!.shopName,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Khoảng cách:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_deliveryEstimate!.estimatedDistanceKm.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Thời gian dự kiến:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_deliveryEstimate!.estimatedDeliveryMinutes} phút',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingEstimate ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoadingEstimate
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Đang tính toán...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Xác nhận địa chỉ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) getLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textLight),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Chọn $label',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    getLabel(item),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
