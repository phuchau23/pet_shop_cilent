import 'package:flutter/material.dart';
import 'package:pet_shop/core/network/api_client.dart';
import 'package:pet_shop/core/theme/app_colors.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import '../../data/models/voucher_response_dto.dart';

class _Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

class _Rad {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// Bottom sheet: nhập mã + danh sách voucher (đủ điều kiện lên trên, kiểu Shopee).
class CheckoutVoucherSheet extends StatefulWidget {
  const CheckoutVoucherSheet({
    super.key,
    required this.orderSubTotal,
    this.initialCode,
    this.initialFieldError,
    required this.onValidateCode,
    required this.onClearSelection,
  });

  final double orderSubTotal;
  final String? initialCode;
  final String? initialFieldError;
  final Future<String?> Function(String code) onValidateCode;
  final VoidCallback onClearSelection;

  @override
  State<CheckoutVoucherSheet> createState() => _CheckoutVoucherSheetState();
}

class _CheckoutVoucherSheetState extends State<CheckoutVoucherSheet> {
  late final TextEditingController _controller;
  late final Future<List<VoucherResponseDto>> _vouchersFuture;
  String? _fieldError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
    _fieldError = widget.initialFieldError;
    _vouchersFuture = _loadVouchers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<VoucherResponseDto>> _loadVouchers() async {
    final client = ApiClient();
    await client.ensureInitialized();
    final ds = OrderRemoteDataSourceImpl(apiClient: client);
    final all = await ds.getVouchers();
    final now = DateTime.now();
    return all.where((v) {
      if (!v.isActive) return false;
      if (v.startDate != null) {
        final s = DateTime.tryParse(v.startDate!);
        if (s != null && now.isBefore(s)) return false;
      }
      if (v.endDate != null) {
        final e = DateTime.tryParse(v.endDate!);
        if (e != null && now.isAfter(e)) return false;
      }
      return true;
    }).toList();
  }

  /// Đủ đơn tối thiểu và còn lượt (nếu có giới hạn).
  bool _isEligible(VoucherResponseDto v) {
    final overLimit = v.usageLimit != null && v.usedCount >= v.usageLimit!;
    if (overLimit) return false;
    if (v.minOrderAmount != null &&
        widget.orderSubTotal < v.minOrderAmount!) {
      return false;
    }
    return true;
  }

  List<VoucherResponseDto> _eligibleFirst(List<VoucherResponseDto> raw) {
    final eligible = raw.where(_isEligible).toList();
    final blocked = raw.where((v) => !_isEligible(v)).toList();
    int byCode(VoucherResponseDto a, VoucherResponseDto b) =>
        a.code.compareTo(b.code);
    eligible.sort(byCode);
    blocked.sort(byCode);
    return [...eligible, ...blocked];
  }

  String _formatMoney(double n) {
    final priceInt = n.toInt();
    final s = priceInt.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _discountLine(VoucherResponseDto v) {
    if (v.discountType == 'percentage') {
      return 'Giảm ${v.discountValue == v.discountValue.roundToDouble() ? v.discountValue.toInt() : v.discountValue}%';
    }
    return 'Giảm ${_formatMoney(v.discountValue)} đ';
  }

  Future<void> _applyCode(String code) async {
    setState(() {
      _submitting = true;
      _fieldError = null;
    });
    final err = await widget.onValidateCode(code.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _fieldError = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _Sp.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _Sp.md,
                _Sp.md,
                _Sp.md,
                _Sp.sm,
              ),
              child: Text(
                'Voucher',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _Sp.md),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Nhập mã voucher',
                  errorText: _fieldError,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.6)
                      : const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Rad.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Rad.md),
                    borderSide: BorderSide(
                      color: textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Rad.md),
                    borderSide: const BorderSide(
                      color: AppColors.primaryDark,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: _Sp.md,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: _Sp.md),
            Expanded(
              child: FutureBuilder<List<VoucherResponseDto>>(
                future: _vouchersFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(_Sp.lg),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryDark,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(_Sp.lg),
                        child: Text(
                          'Không tải được danh sách voucher.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  final raw = snap.data ?? [];
                  if (raw.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có voucher khả dụng.',
                        style: TextStyle(color: textSecondary, fontSize: 15),
                      ),
                    );
                  }

                  final ordered = _eligibleFirst(raw);
                  final eligible =
                      ordered.where(_isEligible).toList(growable: false);
                  final blocked =
                      ordered.where((v) => !_isEligible(v)).toList(
                            growable: false,
                          );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      _Sp.md,
                      0,
                      _Sp.md,
                      _Sp.sm,
                    ),
                    children: [
                      if (eligible.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Dùng được với đơn này',
                          subtitle:
                              '${eligible.length} mã · Đơn ${_formatMoney(widget.orderSubTotal)} đ',
                          isDark: isDark,
                          accent: true,
                        ),
                        const SizedBox(height: _Sp.sm),
                        ...eligible.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: _Sp.sm),
                            child: _VoucherTile(
                              voucher: v,
                              eligible: true,
                              isDark: isDark,
                              discountLine: _discountLine(v),
                              formatMoney: _formatMoney,
                              orderSubTotal: widget.orderSubTotal,
                              submitting: _submitting,
                              onTap: () {
                                _controller.text = v.code;
                                _applyCode(v.code);
                              },
                            ),
                          ),
                        ),
                      ],
                      if (blocked.isNotEmpty) ...[
                        SizedBox(height: eligible.isEmpty ? 0 : _Sp.lg),
                        _SectionHeader(
                          title: 'Chưa dùng được',
                          subtitle:
                              'Đơn chưa đủ tối thiểu hoặc hết lượt',
                          isDark: isDark,
                          accent: false,
                        ),
                        const SizedBox(height: _Sp.sm),
                        ...blocked.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: _Sp.sm),
                            child: _VoucherTile(
                              voucher: v,
                              eligible: false,
                              isDark: isDark,
                              discountLine: _discountLine(v),
                              formatMoney: _formatMoney,
                              orderSubTotal: widget.orderSubTotal,
                              submitting: _submitting,
                              onTap: null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_Sp.md, _Sp.sm, _Sp.md, _Sp.md),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            widget.onClearSelection();
                            Navigator.of(context).pop();
                          },
                    child: Text(
                      'Xóa voucher',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Đóng',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: _Sp.sm),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => _applyCode(_controller.text),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Rad.md),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Áp dụng',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final bool isDark;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.getTextPrimary(isDark);
    final secondary = AppColors.getTextSecondary(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: secondary,
                ),
              ),
            ],
          ),
        ),
        if (accent)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _Sp.sm,
              vertical: _Sp.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(_Rad.sm),
            ),
            child: const Text(
              'Ưu tiên',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({
    required this.voucher,
    required this.eligible,
    required this.isDark,
    required this.discountLine,
    required this.formatMoney,
    required this.orderSubTotal,
    required this.submitting,
    this.onTap,
  });

  final VoucherResponseDto voucher;
  final bool eligible;
  final bool isDark;
  final String discountLine;
  final String Function(double) formatMoney;
  final double orderSubTotal;
  final bool submitting;
  final VoidCallback? onTap;

  String _blockedReason() {
    final overLimit = voucher.usageLimit != null &&
        voucher.usedCount >= voucher.usageLimit!;
    if (overLimit) return 'Đã hết lượt dùng';
    if (voucher.minOrderAmount != null &&
        orderSubTotal < voucher.minOrderAmount!) {
      final need = voucher.minOrderAmount! - orderSubTotal;
      return 'Mua thêm ${formatMoney(need)} đ để dùng';
    }
    return 'Không áp dụng cho đơn này';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    final cardBg = eligible
        ? (isDark ? AppColors.surfaceDark : Colors.white)
        : (isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.45)
            : const Color(0xFFEDEDED));

    final borderColor = eligible
        ? AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.5)
        : textSecondary.withValues(alpha: 0.12);

    final codeColor =
        eligible ? AppColors.primaryDark : textSecondary.withValues(alpha: 0.85);
    final titleColor =
        eligible ? textPrimary : textSecondary.withValues(alpha: 0.9);
    final descColor = eligible
        ? textSecondary
        : textSecondary.withValues(alpha: 0.65);
    final saleColor =
        eligible ? AppColors.sale : textSecondary.withValues(alpha: 0.55);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(_Rad.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (eligible && !submitting) ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_Rad.lg),
            border: Border.all(color: borderColor, width: eligible ? 1.25 : 1),
            boxShadow: eligible
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: eligible
                        ? AppColors.primaryDark
                        : textSecondary.withValues(alpha: 0.25),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _Sp.md,
                      _Sp.md,
                      _Sp.md,
                      _Sp.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      voucher.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: 0.5,
                                        color: codeColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!eligible) ...[
                                    const SizedBox(width: _Sp.xs),
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16,
                                      color: textSecondary.withValues(alpha: 0.55),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: _Sp.sm),
                            Text(
                              discountLine,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: saleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _Sp.sm),
                        Text(
                          voucher.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: titleColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (voucher.description != null &&
                            voucher.description!.isNotEmpty) ...[
                          const SizedBox(height: _Sp.xs),
                          Text(
                            voucher.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: descColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: _Sp.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: _Sp.sm,
                            vertical: _Sp.xs + 1,
                          ),
                          decoration: BoxDecoration(
                            color: eligible
                                ? AppColors.success.withValues(alpha: 0.1)
                                : textSecondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(_Rad.sm),
                          ),
                          child: Text(
                            eligible
                                ? (voucher.minOrderAmount != null
                                    ? 'Đơn từ ${formatMoney(voucher.minOrderAmount!)} đ · Đã đạt'
                                    : 'Áp dụng cho đơn này')
                                : _blockedReason(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: eligible
                                  ? AppColors.success
                                  : textSecondary.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
