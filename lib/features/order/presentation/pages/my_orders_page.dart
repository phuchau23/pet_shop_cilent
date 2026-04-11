import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/order_list_item_dto.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import 'order_tracking_page.dart';

// ─── Status config ─────────────────────────────────────────────────────────

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  final String label;
  const _StatusCfg({required this.color, required this.bg, required this.icon, required this.label});
}

const Map<String, _StatusCfg> _statusMap = {
  'pending':   _StatusCfg(color: Color(0xFFE67E22), bg: Color(0xFFFFF3E0), icon: Icons.access_time_rounded,    label: 'Chờ xác nhận'),
  'confirmed': _StatusCfg(color: Color(0xFF2196F3), bg: Color(0xFFE3F2FD), icon: Icons.check_circle_rounded,   label: 'Đã xác nhận'),
  'shipping':  _StatusCfg(color: Color(0xFF9C27B0), bg: Color(0xFFF3E5F5), icon: Icons.local_shipping_rounded, label: 'Đang giao'),
  'delivered': _StatusCfg(color: Color(0xFF43A047), bg: Color(0xFFE8F5E9), icon: Icons.done_all_rounded,       label: 'Đã giao'),
  'cancelled': _StatusCfg(color: Color(0xFFB0B0B0), bg: Color(0xFFF5F5F5), icon: Icons.cancel_outlined,        label: 'Đã hủy'),
};

_StatusCfg _cfg(String s) =>
    _statusMap[s] ?? const _StatusCfg(color: Colors.grey, bg: Color(0xFFF5F5F5), icon: Icons.help_outline, label: 'Không rõ');

// ─── Page ──────────────────────────────────────────────────────────────────

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});
  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['Tất cả', 'Chờ xác nhận', 'Đã xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'];
  static const List<String?> _statuses = [null, 'pending', 'confirmed', 'shipping', 'delivered', 'cancelled'];

  List<OrderListItemDto> _allOrders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ds = OrderRemoteDataSourceImpl(apiClient: ApiClient());
      final result = await ds.getOrders();
      if (mounted) setState(() { _allOrders = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<OrderListItemDto> _ordersForTab(int i) {
    final status = _statuses[i];
    if (status == null) return _allOrders;
    return _allOrders.where((o) => o.status == status).toList();
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: const Color(0xFF999999),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
                insets: const EdgeInsets.symmetric(horizontal: 6),
              ),
              dividerColor: const Color(0xFFEEEEEE),
              padding: EdgeInsets.zero,
              tabs: _tabs.map((t) => Tab(text: t, height: 44)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, _buildTabContent),
      ),
    );
  }

  Widget _buildTabContent(int i) {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    final orders = _ordersForTab(i);
    if (orders.isEmpty) return _buildEmpty(i);

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) => _OrderCard(
          order: orders[idx],
          fmtPrice: _fmtPrice,
          fmtDate: _fmtDate,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderTrackingPage(orderId: orders[idx].id))),
        ),
      ),
    );
  }

  Widget _buildSkeleton() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
    itemCount: 4,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => const _OrderCardSkeleton(),
  );

  Widget _buildEmpty(int i) {
    final cfg = i > 0 ? _cfg(_statuses[i]!) : null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: cfg?.bg ?? AppColors.primaryVeryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(cfg?.icon ?? Icons.receipt_long_outlined,
                size: 30, color: cfg?.color ?? AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            i == 0 ? 'Chưa có đơn hàng nào' : 'Không có đơn ${_tabs[i].toLowerCase()}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text('Kéo xuống để làm mới',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Không tải được dữ liệu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _fetchOrders,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

// ─── Order Card ────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderListItemDto order;
  final String Function(double) fmtPrice;
  final String Function(String) fmtDate;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.fmtPrice, required this.fmtDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(order.status);
    final canTrack = order.status == 'shipping' || order.status == 'confirmed';
    final isCancelled = order.status == 'cancelled';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Order ID + Status badge ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Pet Shop',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cfg.icon, size: 11, color: cfg.color),
                        const SizedBox(width: 4),
                        Text(cfg.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF2F2F2)),

            // ── Danh sách sản phẩm ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                children: [
                  ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ItemImage(url: item.productImage),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.3),
                              ),
                              const SizedBox(height: 3),
                              Text('x${item.quantity}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(fmtPrice(item.subtotal),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  )),
                  if (order.items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ...order.items.skip(2).take(3).map((item) => Container(
                            width: 24, height: 24,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryVeryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: item.productImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(item.productImage!, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 12, color: AppColors.primary)))
                                : const Icon(Icons.pets, size: 12, color: AppColors.primary),
                          )),
                          const SizedBox(width: 4),
                          Text('+${order.items.length - 2} sản phẩm',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF2F2F2)),

            // ── Footer: ngày + tổng tiền ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
              child: Row(
                children: [
                  Icon(Icons.receipt_outlined, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Đơn #${order.id}  ·  ${fmtDate(order.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    fmtPrice(order.finalAmount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isCancelled ? const Color(0xFFB0B0B0) : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // ── Track button ──
            if (canTrack)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryDark, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.location_on_rounded, size: 15),
                    label: const Text('Theo dõi đơn hàng',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Item image ────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  final String? url;
  const _ItemImage({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 54, height: 54,
        color: AppColors.primaryVeryLight,
        child: url != null
            ? Image.network(url!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 22, color: AppColors.primary))
            : const Icon(Icons.pets, size: 22, color: AppColors.primary),
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────

class _OrderCardSkeleton extends StatefulWidget {
  const _OrderCardSkeleton();
  @override
  State<_OrderCardSkeleton> createState() => _OrderCardSkeletonState();
}

class _OrderCardSkeletonState extends State<_OrderCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _s => Color.lerp(const Color(0xFFF5EDEF), const Color(0xFFEBDEE1), _anim.value)!;

  Widget _box(double w, double h, {double r = 5}) =>
      Container(width: w, height: h, decoration: BoxDecoration(color: _s, borderRadius: BorderRadius.circular(r)));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  _box(90, 13), const Spacer(), _box(80, 22, r: 20),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFF2F2F2)),
            // Products skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(children: [
                _skeletonItem(),
                const SizedBox(height: 8),
                _skeletonItem(),
              ]),
            ),
            Container(height: 1, color: const Color(0xFFF2F2F2)),
            // Footer skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
              child: Row(children: [_box(140, 10), const Spacer(), _box(70, 15)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonItem() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _box(54, 54, r: 8), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _box(double.infinity, 12), const SizedBox(height: 6), _box(60, 10),
      ])),
      const SizedBox(width: 8), _box(55, 13),
    ],
  );
}
