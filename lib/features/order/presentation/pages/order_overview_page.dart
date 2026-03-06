import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/store_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../../auth/data/datasources/remote/auth_remote_data_source.dart';
import '../../domain/entities/address_result.dart';
import '../../data/models/estimate_delivery_request_dto.dart';
import '../../data/models/estimate_delivery_response_dto.dart';
import '../../data/models/validate_voucher_request_dto.dart';
import '../../data/models/voucher_response_dto.dart';
import '../../data/models/create_order_request_dto.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import 'address_selection_page.dart';
import 'order_tracking_page.dart';

class OrderOverviewPage extends ConsumerStatefulWidget {
  final List<CartItem> selectedItems;

  const OrderOverviewPage({super.key, required this.selectedItems});

  @override
  ConsumerState<OrderOverviewPage> createState() => _OrderOverviewPageState();
}

class _OrderOverviewPageState extends ConsumerState<OrderOverviewPage> {
  String? _selectedAddress;
  String? _selectedVoucher;
  String? _userName;
  String? _userPhone;

  // Location selection - lưu full result để dùng khi submit order
  AddressResult? _selectedAddressResult;

  // Delivery estimate
  bool _isLoadingEstimate = false;
  List<LatLng>? _routePolyline;
  final MapController _mapController = MapController();
  double? _routeDistance; // km
  int? _routeDuration; // phút
  LatLng? _storeLocation; // Tọa độ cửa hàng
  double? _deliveryFee; // ⭐ Phí ship từ API

  // Voucher
  VoucherResponseDto? _voucher;
  double _voucherDiscount = 0; // ⭐ Discount từ API
  bool _isValidatingVoucher = false;
  String? _voucherError;

  // Create order
  bool _isCreatingOrder = false;

  // Payment method: 1 = COD, 2 = VN-Pay
  int _selectedPaymentMethod = 1; // Mặc định COD

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadStoreLocation();
    // Mock địa chỉ mặc định
    _selectedAddress = null;
    _selectedVoucher = null;
  }

  Future<void> _loadStoreLocation() async {
    final lat = await StoreStorage.getStoreLatitude();
    final lng = await StoreStorage.getStoreLongitude();
    setState(() {
      _storeLocation = LatLng(lat, lng);
    });
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<AddressResult>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddressSelectionPage(initialAddress: _selectedAddressResult),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddressResult = result;
        _selectedAddress = result.fullAddress;
        _routePolyline = null;
      });

      // Nếu có delivery estimate, cập nhật thông tin từ BE
      if (result.deliveryEstimate != null) {
        _updateRouteFromEstimate(result.deliveryEstimate!);
      } else {
        // Nếu chưa có estimate, call API để lấy route từ BE
        await _estimateDelivery(result.latitude, result.longitude);
      }
    }
  }

  /// Gọi API estimate-delivery từ BE để lấy route và deliveryFee
  Future<void> _estimateDelivery(double customerLat, double customerLng) async {
    try {
      setState(() {
        _isLoadingEstimate = true;
      });

      final dataSource = OrderRemoteDataSourceImpl(apiClient: ApiClient());

      // Gửi orderTotal để tính free delivery nếu >= 500k
      final request = EstimateDeliveryRequestDto(
        customerLat: customerLat,
        customerLng: customerLng,
        orderTotal: _subTotal, // Gửi tổng tiền để BE tính free delivery
      );

      final response = await dataSource.estimateDelivery(request);

      // Cập nhật route từ BE response
      _updateRouteFromEstimate(response);
    } catch (e) {
      print('❌ Error estimating delivery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tính phí ship: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingEstimate = false;
      });
    }
  }

  void _updateRouteFromEstimate(EstimateDeliveryResponseDto estimate) {
    setState(() {
      // Convert route coordinates to LatLng list từ BE
      // API trả về [lng, lat] nên cần đảo ngược
      if (estimate.routeCoordinates.isNotEmpty) {
        _routePolyline = estimate.routeCoordinates
            .map((coord) => LatLng(coord[1], coord[0]))
            .toList();
        print('✅ Route polyline có ${_routePolyline!.length} điểm');
      } else {
        print('⚠️ Route coordinates rỗng');
      }

      // Cập nhật distance và duration từ BE response
      _routeDistance = estimate.estimatedDistanceKm;
      _routeDuration = estimate.estimatedDeliveryMinutes;

      // ⭐ Cập nhật deliveryFee từ BE (KHÔNG tự tính)
      _deliveryFee = estimate.deliveryFee;

      // Cập nhật store location từ BE
      _storeLocation = LatLng(estimate.shopLat, estimate.shopLng);
    });

    // Di chuyển map để hiển thị cả route
    if (_routePolyline != null &&
        _routePolyline!.isNotEmpty &&
        _selectedAddressResult != null) {
      // Tính bounds để fit cả route và markers
      final shopLatLng = LatLng(estimate.shopLat, estimate.shopLng);
      final customerLatLng = LatLng(
        _selectedAddressResult!.latitude,
        _selectedAddressResult!.longitude,
      );
      final allPoints = [shopLatLng, customerLatLng, ..._routePolyline!];
      final bounds = LatLngBounds.fromPoints(allPoints);

      // Đợi map được render xong rồi mới fit bounds
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        }
      });
    }
  }

  /// Validate voucher qua API
  Future<void> _validateVoucher(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _voucher = null;
        _voucherDiscount = 0;
        _selectedVoucher = null;
        _voucherError = null;
      });
      return;
    }

    try {
      setState(() {
        _isValidatingVoucher = true;
        _voucherError = null;
      });

      final dataSource = OrderRemoteDataSourceImpl(apiClient: ApiClient());

      final request = ValidateVoucherRequestDto(
        code: code,
        orderAmount: _subTotal, // Tổng tiền sản phẩm (trước giảm giá)
      );

      final voucher = await dataSource.validateVoucher(request);

      // Tính discount để preview (BE sẽ tính lại khi submit)
      double discount = 0;
      if (voucher.discountType == 'percentage') {
        discount = _subTotal * (voucher.discountValue / 100);
        if (voucher.maxDiscountAmount != null &&
            discount > voucher.maxDiscountAmount!) {
          discount = voucher.maxDiscountAmount!;
        }
      } else {
        discount = voucher.discountValue;
        if (discount > _subTotal) discount = _subTotal;
      }

      setState(() {
        _voucher = voucher;
        _voucherDiscount = discount;
        _selectedVoucher = voucher.code;
        _voucherError = null;
      });
    } catch (e) {
      print('❌ Error validating voucher: $e');
      setState(() {
        _voucher = null;
        _voucherDiscount = 0;
        _selectedVoucher = null;
        _voucherError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi voucher: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isValidatingVoucher = false;
      });
    }
  }

  /// Create order qua API
  Future<void> _createOrder() async {
    if (_selectedAddressResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ giao hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_userName == null || _userPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cập nhật thông tin người đặt hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isCreatingOrder = true;
      });

      final dataSource = OrderRemoteDataSourceImpl(apiClient: ApiClient());

      // Tạo order items từ cart items
      final items = widget.selectedItems.map((item) {
        return OrderItemDto(
          productId: item.product.productId,
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.productSize.price,
          subtotal: item.totalPrice,
        );
      }).toList();

      final request = CreateOrderRequestDto(
        customer: CustomerDto(name: _userName!, phone: _userPhone!),
        deliveryAddress: DeliveryAddressDto(
          addressDetail: _selectedAddressResult!.fullAddress,
          fullAddress: _selectedAddressResult!.fullAddress,
          lat: _selectedAddressResult!.latitude,
          lng: _selectedAddressResult!.longitude,
          wardCode: _selectedAddressResult!.wardCode,
          districtCode: _selectedAddressResult!.districtCode,
          provinceCode: _selectedAddressResult!.provinceCode,
        ),
        items: items,
        totalPrice: _subTotal,
        voucherCode: _selectedVoucher,
        paymentMethod: _selectedPaymentMethod, // 1 = COD, 2 = VN-Pay
      );

      final order = await dataSource.createOrder(request);

      // Order created successfully - Navigate to tracking page
      if (mounted) {
        // Pop tất cả các màn hình trước đó và navigate đến tracking page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderTrackingPage(orderId: order.id),
          ),
          (route) => false, // Xóa tất cả routes trước đó
        );
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt hàng: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      // ⭐ Lấy profile từ API /api/auth/profile
      final authDataSource = AuthRemoteDataSourceImpl(apiClient: ApiClient());
      final profile = await authDataSource.getProfile();

      setState(() {
        _userName = profile.fullName ?? profile.email;
        _userPhone = profile.phoneNumber ?? 'Chưa cập nhật';
      });
    } catch (e) {
      print('❌ Error loading user info: $e');
      setState(() {
        _userName = 'Người dùng';
        _userPhone = 'Chưa cập nhật';
      });
    }
  }

  String _formatPrice(double price) {
    if (price.isNaN || price.isInfinite || price < 0) {
      return '0 đ';
    }
    final priceInt = price.toInt();
    final priceString = priceInt.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if (i > 0 && (priceString.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }
    return '${buffer.toString()} đ';
  }

  double get _subTotal {
    return widget.selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  double get _shippingFee {
    // ⭐ Sử dụng deliveryFee từ API (KHÔNG tự tính)
    return _deliveryFee ?? 0;
  }

  double get _total {
    return _subTotal - _voucherDiscount + _shippingFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            title: const Text(
              'Tổng quan đơn hàng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Thông tin người đặt hàng
                _buildCustomerInfo(),
                const SizedBox(height: 12),
                // Chọn địa chỉ
                _buildAddressSection(),
                const SizedBox(height: 12),
                // Map và thông tin giao hàng (TikTok Shop style)
                if (_selectedAddressResult != null) ...[
                  _buildDeliveryMapWithInfo(),
                  const SizedBox(height: 12),
                ],
                // Thông tin đơn hàng
                _buildOrderItems(),
                const SizedBox(height: 12),
                // Thời gian nhận hàng
                _buildDeliveryTime(),
                const SizedBox(height: 12),
                // Voucher
                _buildVoucherSection(),
                const SizedBox(height: 12),
                // Hình thức thanh toán
                _buildPaymentMethodSection(),
                const SizedBox(height: 12),
                // Tóm tắt đơn hàng
                _buildOrderSummary(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin người đặt hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Họ và tên',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName ?? 'Đang tải...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số điện thoại',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userPhone ?? 'Đang tải...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Địa chỉ nhận hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectAddress,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedAddress == null
                      ? AppColors.textLight
                      : AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedAddress == null
                    ? Colors.grey.shade50
                    : AppColors.primaryVeryLight,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: _selectedAddress == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedAddress == null
                        ? const Text(
                            'Chọn địa chỉ nhận hàng',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Text(
                            _selectedAddress!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _selectedAddress == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.selectedItems.map((item) => _buildOrderItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(CartItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: item.product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.images[0],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pets,
                            color: AppColors.primary,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.pets, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sizeName} x ${item.quantity}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              _formatPrice(item.totalPrice),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Map với thông tin giao hàng (TikTok Shop style)
  Widget _buildDeliveryMapWithInfo() {
    if (_selectedAddressResult == null) return const SizedBox.shrink();

    // Lấy tọa độ shop và customer
    final customerLatLng = LatLng(
      _selectedAddressResult!.latitude,
      _selectedAddressResult!.longitude,
    );

    // Lấy shop location từ estimate hoặc store storage
    LatLng? shopLatLng;
    if (_selectedAddressResult!.deliveryEstimate != null) {
      final estimate = _selectedAddressResult!.deliveryEstimate!;
      shopLatLng = LatLng(estimate.shopLat, estimate.shopLng);
    } else if (_storeLocation != null) {
      shopLatLng = _storeLocation;
    }

    // Center point cho map
    final centerLatLng = shopLatLng != null
        ? LatLng(
            (shopLatLng.latitude + customerLatLng.latitude) / 2,
            (shopLatLng.longitude + customerLatLng.longitude) / 2,
          )
        : customerLatLng;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Map lớn (TikTok Shop style)
          Container(
            height: 350,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: _isLoadingEstimate
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: centerLatLng,
                        initialZoom:
                            _routePolyline != null && _routePolyline!.isNotEmpty
                            ? 13.0
                            : 15.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Light theme tiles (màu sáng)
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.petshop.app',
                          maxZoom: 19,
                        ),
                        // Route polyline (màu xanh dương như Google Maps)
                        if (_routePolyline != null &&
                            _routePolyline!.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePolyline!,
                                strokeWidth: 5.0,
                                color: const Color(
                                  0xFF4285F4,
                                ), // Google Maps blue
                              ),
                            ],
                          ),
                        // Markers
                        MarkerLayer(
                          markers: [
                            // Shop marker (màu cam)
                            if (shopLatLng != null)
                              Marker(
                                point: shopLatLng,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800), // Màu cam
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
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
                                    size: 24,
                                  ),
                                ),
                              ),
                            // Customer marker (màu đỏ)
                            Marker(
                              point: customerLatLng,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEA4335,
                                  ), // Màu đỏ Google
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
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
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          // Thông tin giao hàng ở dưới map (TikTok Shop style)
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
            child: Row(
              children: [
                // Thời gian dự kiến
                Expanded(
                  child: _buildDeliveryInfoItem(
                    icon: Icons.access_time,
                    label: 'Thời gian',
                    value: _routeDuration != null
                        ? '${_routeDuration} phút'
                        : (_selectedAddressResult!.deliveryEstimate != null
                              ? '${_selectedAddressResult!.deliveryEstimate!.estimatedDeliveryMinutes} phút'
                              : 'Đang tính...'),
                    color: AppColors.primary,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                // Khoảng cách
                Expanded(
                  child: _buildDeliveryInfoItem(
                    icon: Icons.straighten,
                    label: 'Khoảng cách',
                    value: _routeDistance != null
                        ? '${_routeDistance!.toStringAsFixed(1)} km'
                        : (_selectedAddressResult!.deliveryEstimate != null
                              ? '${_selectedAddressResult!.deliveryEstimate!.estimatedDistanceKm.toStringAsFixed(1)} km'
                              : 'Đang tính...'),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDeliveryTime() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nhận vào từ 1-2 tiếng kể từ khi đặt hàng',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _showVoucherDialog();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedVoucher == null
                      ? AppColors.textLight
                      : AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedVoucher == null
                    ? Colors.grey.shade50
                    : AppColors.primaryVeryLight,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: _selectedVoucher == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedVoucher == null
                        ? const Text(
                            'Chọn voucher',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Text(
                            _selectedVoucher!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _selectedVoucher == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // COD option
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 1
                      ? AppColors.primary
                      : AppColors.textLight,
                  width: _selectedPaymentMethod == 1 ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedPaymentMethod == 1
                    ? AppColors.primaryVeryLight
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedPaymentMethod == 1
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: _selectedPaymentMethod == 1
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: _selectedPaymentMethod == 1
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.money, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thanh toán khi nhận hàng (COD)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thanh toán bằng tiền mặt khi nhận hàng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // VN-Pay option
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 2;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 2
                      ? AppColors.primary
                      : AppColors.textLight,
                  width: _selectedPaymentMethod == 2 ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedPaymentMethod == 2
                    ? AppColors.primaryVeryLight
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedPaymentMethod == 2
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: _selectedPaymentMethod == 2
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: _selectedPaymentMethod == 2
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8), // VN-Pay blue
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'VN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VN-Pay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thanh toán online qua VN-Pay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Tạm tính
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                _formatPrice(_subTotal),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Voucher discount
          if (_selectedVoucher != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giảm giá:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '-${_formatPrice(_voucherDiscount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          // Shipping fee
          if (_deliveryFee != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí vận chuyển:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _shippingFee == 0 ? 'Miễn phí' : _formatPrice(_shippingFee),
                  style: TextStyle(
                    fontSize: 14,
                    color: _shippingFee == 0
                        ? AppColors.success
                        : AppColors.textPrimary,
                    fontWeight: _shippingFee == 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Tổng cộng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatPrice(_total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
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
            onPressed: (_selectedAddress == null || _isCreatingOrder)
                ? null
                : _createOrder,
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
            child: _isCreatingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đặt hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  /// Show dialog để nhập voucher code
  void _showVoucherDialog() {
    final voucherController = TextEditingController(
      text: _selectedVoucher ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: voucherController,
              decoration: InputDecoration(
                hintText: 'Nhập mã voucher',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _voucherError,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            if (_voucher != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _voucher!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (_voucher!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _voucher!.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Xóa voucher
              setState(() {
                _voucher = null;
                _voucherDiscount = 0;
                _selectedVoucher = null;
                _voucherError = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Xóa'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _isValidatingVoucher
                ? null
                : () async {
                    final code = voucherController.text.trim();
                    if (code.isEmpty) {
                      setState(() {
                        _voucher = null;
                        _voucherDiscount = 0;
                        _selectedVoucher = null;
                        _voucherError = null;
                      });
                      Navigator.of(context).pop();
                      return;
                    }

                    await _validateVoucher(code);
                    if (mounted && _voucherError == null) {
                      Navigator.of(context).pop();
                    }
                  },
            child: _isValidatingVoucher
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
