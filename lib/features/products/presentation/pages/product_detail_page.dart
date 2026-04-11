import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/pages/cart_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;
  ProductSize? _selectedSize;

  String _formatPrice(double price) {
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

  @override
  void initState() {
    super.initState();
    // Set default selected size if available (chọn size đầu tiên có sẵn)
    if (widget.product.productSizes.isNotEmpty) {
      final firstAvailableSize = widget.product.productSizes.firstWhere(
        (ps) => ps.isActive && ps.isInStock,
        orElse: () => widget.product.productSizes.first,
      );
      _selectedSize = firstAvailableSize;
    }
  }

  // Get current price based on selected size
  double get _currentPrice {
    if (_selectedSize != null) {
      return _selectedSize!.price;
    }
    return widget.product.price; // Fallback to product's base price
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: AppColors.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textLight.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              // Shopping Cart Icon with Badge
              _CartIconWithBadge(ref: ref),
              // Favorite Icon
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_outline_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Add to favorites
                  },
                ),
              ),
            ],
          ),

          // Product Images - Main image left, thumbnails right (at the top)
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final paddingLeft = 0.0;
                  final paddingRight = 0.0;
                  final spacing =
                      12.0; // spacing between main image and thumbnails
                  final thumbnailWidth = 72.0;
                  final availableWidth =
                      screenWidth -
                      paddingLeft -
                      paddingRight -
                      spacing -
                      thumbnailWidth;
                  final mainImageSize = availableWidth;

                  // Always 4 thumbnail slots
                  final thumbnailSlotCount = 4;
                  final thumbnailSpacing = 12.0;
                  final totalThumbnailSpacing =
                      thumbnailSpacing * (thumbnailSlotCount - 1);
                  final thumbnailHeight =
                      (mainImageSize - totalThumbnailSpacing) /
                      thumbnailSlotCount;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main image (left)
                      SizedBox(
                        width: mainImageSize,
                        height: mainImageSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryVeryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textLight.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images[_selectedImageIndex],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            color: AppColors.primaryVeryLight,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primary),
                                              ),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.primaryVeryLight,
                                        child: const Icon(
                                          Icons.pets,
                                          size: 100,
                                          color: AppColors.primary,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: AppColors.primaryVeryLight,
                                    child: const Icon(
                                      Icons.pets,
                                      size: 100,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      // Thumbnails (right) - always 4 slots
                      SizedBox(width: spacing),
                      SizedBox(
                        width: thumbnailWidth,
                        height: mainImageSize,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(thumbnailSlotCount, (index) {
                            final hasImage = index < product.images.length;
                            final imageUrl = hasImage
                                ? product.images[index]
                                : null;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < thumbnailSlotCount - 1
                                    ? thumbnailSpacing
                                    : 0,
                              ),
                              child: hasImage
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImageIndex = index;
                                        });
                                      },
                                      child: Container(
                                        width: thumbnailWidth,
                                        height: thumbnailHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _selectedImageIndex == index
                                                ? AppColors.primary
                                                : AppColors.textLight.withOpacity(0.2),
                                            width: _selectedImageIndex == index
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(9),
                                          child: Image.network(
                                            imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color: AppColors
                                                        .primaryVeryLight,
                                                    child: const Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              AppColors.primary,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: AppColors
                                                        .primaryVeryLight,
                                                    child: const Icon(
                                                      Icons.pets,
                                                      color: AppColors.primary,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: thumbnailWidth,
                                      height: thumbnailHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.textLight
                                              .withOpacity(0.15),
                                          width: 1,
                                        ),
                                        color: Colors.transparent,
                                      ),
                                    ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Product Info
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sale badge
                        if (product.isOnSale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.saleBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Giảm ${product.discountPercent.toInt()}%',
                              style: const TextStyle(
                                color: AppColors.sale,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        if (product.isOnSale) const SizedBox(height: 12),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              product.brand.name,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryVeryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.petType ?? 'Chó, Mèo',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(_currentPrice),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                            if (_selectedSize != null)
                              Text(
                                _selectedSize!.isInStock
                                    ? 'Tồn kho: ${_selectedSize!.stockQuantity}'
                                    : 'Tồn kho: 0',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.rating,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${product.soldCount ?? 0} đã bán)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Size selector
                        if (product.productSizes.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const Text(
                            'Kích thước',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: product.productSizes
                                .where((ps) => ps.isActive)
                                .map((productSize) {
                                  final isSelected =
                                      _selectedSize?.productSizeId ==
                                      productSize.productSizeId;
                                  final isOutOfStock = !productSize.isInStock;
                                  return GestureDetector(
                                    onTap: isOutOfStock
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedSize = productSize;
                                            });
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isOutOfStock
                                                  ? AppColors.primaryVeryLight
                                                  : AppColors.surface),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isOutOfStock
                                                    ? AppColors.textLight
                                                          .withOpacity(0.2)
                                                    : AppColors.textLight.withOpacity(0.25)),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          productSize.size,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isOutOfStock
                                                      ? AppColors.textLight
                                                      : AppColors.textPrimary),
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.textLight.withOpacity(0.1),
                    indent: 20,
                    endIndent: 20,
                  ),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô tả sản phẩm',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryVeryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Còn ${product.stockQuantity} sản phẩm',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

      // Bottom bar với quantity và add to cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.textLight.withOpacity(0.12),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.25),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      color: AppColors.textPrimary,
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      color: AppColors.textPrimary,
                      onPressed:
                          _selectedSize != null &&
                              _quantity < _selectedSize!.stockQuantity
                          ? () {
                              setState(() {
                                _quantity++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add to cart button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isAddingToCart
                      ? null
                      : () async {
                          // Validate size đã được chọn
                          if (_selectedSize == null) {
                            ToastNotification.error(
                              context,
                              'Vui lòng chọn size',
                            );
                            return;
                          }

                          // Validate quantity không vượt quá stock
                          if (_quantity > _selectedSize!.stockQuantity) {
                            ToastNotification.error(
                              context,
                              'Số lượng vượt quá tồn kho (Còn ${_selectedSize!.stockQuantity})',
                            );
                            return;
                          }

                          final userId = await UserStorage.getUserId();
                          if (userId == null) {
                            ToastNotification.error(
                              context,
                              'Vui lòng đăng nhập',
                            );
                            return;
                          }

                          setState(() {
                            _isAddingToCart = true;
                          });

                          try {
                            final cartNotifier = ref.read(
                              cartNotifierProvider(userId).notifier,
                            );
                            final countNotifier = ref.read(
                              cartCountNotifierProvider(userId).notifier,
                            );

                            await cartNotifier.addToCart(
                              widget.product,
                              _selectedSize!,
                              _quantity,
                            );
                            await countNotifier.refresh();

                            if (mounted) {
                              ToastNotification.success(
                                context,
                                'Đã thêm vào giỏ hàng',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ToastNotification.error(
                                context,
                                'Lỗi: $e',
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isAddingToCart = false;
                              });
                            }
                          }
                        },
                  child: _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Thêm vào giỏ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartIconWithBadge extends ConsumerWidget {
  final WidgetRef ref;

  const _CartIconWithBadge({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int?>(
      future: UserStorage.getUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textLight.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () {},
          ),
        );
        }

        final userId = snapshot.data!;
        final cartCountAsync = ref.watch(cartCountNotifierProvider(userId));

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textLight.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              cartCountAsync.when(
                data: (count) {
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
