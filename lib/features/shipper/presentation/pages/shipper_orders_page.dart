import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../features/shipper/data/datasources/remote/shipper_remote_data_source.dart';
import '../../../../features/shipper/data/models/shipper_order_response_dto.dart';
import '../../../../features/shipper/data/models/update_shipper_status_request_dto.dart';
import '../../services/location_tracking_service.dart';

class ShipperOrdersPage extends StatefulWidget {
  const ShipperOrdersPage({super.key});

  @override
  State<ShipperOrdersPage> createState() => _ShipperOrdersPageState();
}

class _ShipperOrdersPageState extends State<ShipperOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ShipperRemoteDataSource _shipperDataSource;
  final LocationTrackingService _locationTrackingService =
      LocationTrackingService();
  int? _shipperId;

  // Available orders (chờ nhận đơn)
  List<ShipperOrderResponseDto> _availableOrders = [];
  bool _loadingAvailable = false;

  // My orders (đang giao, đã giao)
  List<ShipperOrderResponseDto> _myOrders = [];
  bool _loadingMyOrders = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _shipperDataSource = ShipperRemoteDataSourceImpl(apiClient: ApiClient());
    _loadShipperId();
    _tabController.addListener(_onTabChanged);
  }

  Future<void> _loadShipperId() async {
    final userId = await UserStorage.getUserId();
    setState(() {
      _shipperId = userId;
    });
    if (_shipperId != null) {
      _loadOrders();
      // Kiểm tra và resume tracking ngay khi vào app (kể cả sau logout/login lại)
      _checkAndResumeTracking();
    }
  }

  /// Kiểm tra xem có đơn đang giao không → tự động resume tracking
  /// Chạy ngay lúc init, không phụ thuộc vào tab nào đang active
  Future<void> _checkAndResumeTracking() async {
    if (_locationTrackingService.isTracking) return;
    try {
      final shippingOrders = await _shipperDataSource.getMyOrders(status: 'shipping');
      if (shippingOrders.isNotEmpty && !_locationTrackingService.isTracking) {
        await _locationTrackingService.startTracking(shippingOrders.first.id);
        print('✅ Resumed tracking for order ${shippingOrders.first.id}');
      }
    } catch (e) {
      print('⚠️ Could not resume tracking on startup: $e');
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (_shipperId == null) return;

    final currentIndex = _tabController.index;

    if (currentIndex == 0) {
      // Tab "Chờ nhận đơn"
      await _loadAvailableOrders();
    } else {
      // Tab "Đang giao" hoặc "Đã giao"
      String status = currentIndex == 1 ? 'shipping' : 'delivered';
      await _loadMyOrders(status: status);
    }
  }

  Future<void> _loadAvailableOrders() async {
    setState(() {
      _loadingAvailable = true;
    });

    try {
      final orders = await _shipperDataSource.getAvailableOrders();
      setState(() {
        _availableOrders = orders;
        _loadingAvailable = false;
      });
    } catch (e) {
      print('❌ Error loading available orders: $e');
      setState(() {
        _loadingAvailable = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMyOrders({String? status}) async {
    setState(() {
      _loadingMyOrders = true;
    });

    try {
      final orders = await _shipperDataSource.getMyOrders(status: status);
      setState(() {
        _myOrders = orders;
        _loadingMyOrders = false;
      });

      // Auto-resume tracking nếu có đơn đang giao và chưa tracking
      if (status == 'shipping' && orders.isNotEmpty && !_locationTrackingService.isTracking) {
        try {
          await _locationTrackingService.startTracking(orders.first.id);
          print('✅ Auto-resumed location tracking for order ${orders.first.id}');
        } catch (e) {
          print('⚠️ Could not auto-resume location tracking: $e');
        }
      }
    } catch (e) {
      print('❌ Error loading my orders: $e');
      setState(() {
        _loadingMyOrders = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptOrder(ShipperOrderResponseDto order) async {
    if (_shipperId == null) return;

    try {
      setState(() {
        _loadingAvailable = true;
      });

      // Lấy vị trí GPS hiện tại để gửi lên BE (bắt buộc khi nhận đơn)
      double? currentLat;
      double? currentLng;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 8),
            );
            currentLat = position.latitude;
            currentLng = position.longitude;
          }
        }
      } catch (e) {
        print('⚠️ Could not get GPS location: $e');
      }

      final request = UpdateShipperStatusRequestDto(
        shipperId: _shipperId!,
        status: 'shipping',
        lat: currentLat,
        lng: currentLng,
      );

      await _shipperDataSource.updateShipperStatus(order.id, request);

      // Bắt đầu tracking GPS
      try {
        await _locationTrackingService.startTracking(order.id);
        print('✅ Started location tracking for order ${order.id}');
      } catch (e) {
        print('⚠️ Could not start location tracking: $e');
        // Vẫn tiếp tục dù tracking fail
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã nhận đơn hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload orders
        await _loadAvailableOrders();
        // Switch to "Đang giao" tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      print('❌ Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAvailable = false;
        });
      }
    }
  }

  Future<void> _handleDeliverOrder(ShipperOrderResponseDto order) async {
    if (_shipperId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Xác nhận đã giao hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _loadingMyOrders = true;
      });

      final request = UpdateShipperStatusRequestDto(
        shipperId: _shipperId!,
        status: 'delivered',
      );

      await _shipperDataSource.updateShipperStatus(order.id, request);

      // Dừng tracking GPS khi đã giao
      if (_locationTrackingService.currentOrderId == order.id) {
        await _locationTrackingService.stopTracking();
        print('✅ Stopped location tracking for order ${order.id}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái giao hàng!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload orders
        await _loadMyOrders(status: 'shipping');
        // Switch to "Đã giao" tab
        _tabController.animateTo(2);
      }
    } catch (e) {
      print('❌ Error delivering order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingMyOrders = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _locationTrackingService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn Hàng Của Tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ nhận đơn'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Đã giao'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: Chờ nhận đơn
          _buildAvailableOrdersTab(),
          // Tab: Đang giao
          _buildMyOrdersTab('shipping'),
          // Tab: Đã giao
          _buildMyOrdersTab('delivered'),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab() {
    if (_loadingAvailable) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào đang chờ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableOrders.length,
        itemBuilder: (context, index) {
          final order = _availableOrders[index];
          return _buildOrderCard(order, showAcceptButton: true);
        },
      ),
    );
  }

  Widget _buildMyOrdersTab(String status) {
    if (_loadingMyOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMyOrders(status: status),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myOrders.length,
        itemBuilder: (context, index) {
          final order = _myOrders[index];
          return _buildOrderCard(
            order,
            showAcceptButton: false,
            showDeliverButton: status == 'shipping',
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    ShipperOrderResponseDto order, {
    required bool showAcceptButton,
    bool showDeliverButton = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Khách hàng', order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'SĐT', order.customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Địa chỉ', order.fullAddress),
            if (order.estimatedDistanceMeters != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.straighten,
                'Khoảng cách',
                '${(order.estimatedDistanceMeters! / 1000).toStringAsFixed(1)} km',
              ),
            ],
            if (order.estimatedDeliveryMinutes != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Thời gian dự kiến',
                '${order.estimatedDeliveryMinutes} phút',
              ),
            ],
            if (order.finalAmount != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.payments,
                'Tổng tiền',
                '${order.finalAmount!.toStringAsFixed(0)} đ',
              ),
            ],
            // Map preview và route (chỉ hiển thị cho available orders)
            if (showAcceptButton &&
                order.customerLat != null &&
                order.customerLng != null) ...[
              const SizedBox(height: 16),
              _buildRouteMapPreview(order),
              const SizedBox(height: 12),
              // Nút mở Google Maps navigation
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleMapsNavigation(order),
                  icon: const Icon(Icons.navigation, size: 20),
                  label: const Text(
                    'Chỉ dẫn đường đi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
            if (showAcceptButton || showDeliverButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showAcceptButton
                      ? () => _handleAcceptOrder(order)
                      : () => _handleDeliverOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showAcceptButton
                        ? Colors.green
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    showAcceptButton ? 'Nhận đơn' : 'Đã giao hàng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.orange;
      case 'shipping':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      default:
        return status;
    }
  }

  Widget _buildRouteMapPreview(ShipperOrderResponseDto order) {
    if (order.customerLat == null || order.customerLng == null) {
      return const SizedBox.shrink();
    }

    final shopLatLng = LatLng(order.shopLat, order.shopLng);
    final customerLatLng = LatLng(order.customerLat!, order.customerLng!);

    // Center point giữa shop và customer
    final centerLat = (order.shopLat + order.customerLat!) / 2;
    final centerLng = (order.shopLng + order.customerLng!) / 2;
    final centerLatLng = LatLng(centerLat, centerLng);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: centerLatLng,
            initialZoom: 13.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.petshop.app',
              maxZoom: 19,
            ),
            // Polyline - Route từ shop đến customer
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [shopLatLng, customerLatLng],
                  strokeWidth: 3.0,
                  color: Colors.blue.withOpacity(0.7),
                ),
              ],
            ),
            // Markers
            MarkerLayer(
              markers: [
                // Shop marker
                Marker(
                  point: shopLatLng,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800), // Orange
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Customer marker
                Marker(
                  point: customerLatLng,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335), // Red
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMapsNavigation(ShipperOrderResponseDto order) async {
    final lat = order.customerLat;
    final lng = order.customerLng;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có thông tin địa chỉ khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mở Google Maps với navigation đến địa chỉ khách hàng

    // URL cho Google Maps navigation
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    // Hoặc dùng app Google Maps nếu có
    final googleMapsAppUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    try {
      // Thử mở Google Maps app trước
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        // Fallback về web
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể mở Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
