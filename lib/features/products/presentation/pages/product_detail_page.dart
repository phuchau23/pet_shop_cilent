import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/user_storage.dart';
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
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
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
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppColors.textPrimary,
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
              color: Colors.white,
              padding: const EdgeInsets.only(
                left: 8,
                right: 0,
                top: 16,
                bottom: 16,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final paddingLeft = 8.0;
                  final paddingRight = 0;
                  final spacing =
                      12.0; // spacing between main image and thumbnails
                  final thumbnailWidth = 80.0;
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _selectedImageIndex == index
                                                ? AppColors.primary
                                                : AppColors.textLight,
                                            width: _selectedImageIndex == index
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
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
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.textLight
                                              .withOpacity(0.3),
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
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sale badge
                        if (product.isOnSale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.saleBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Giảm ${product.discountPercent.toInt()}%',
                              style: const TextStyle(
                                color: AppColors.sale,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              product.brand.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryVeryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.petType ?? 'Chó, Mèo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPrice(_currentPrice),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_selectedSize != null)
                              Text(
                                _selectedSize!.isInStock
                                    ? 'Tồn kho: ${_selectedSize!.stockQuantity}'
                                    : 'Tồn kho: 0',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.rating,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${product.soldCount ?? 0} đã bán)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Size selector
                        if (product.productSizes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Select Size:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
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
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isOutOfStock
                                                  ? AppColors.primaryVeryLight
                                                  : Colors.white),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isOutOfStock
                                                    ? AppColors.textLight
                                                          .withOpacity(0.3)
                                                    : AppColors.textLight),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
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

                  const Divider(height: 32),

                  // Description
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô Tả Sản Phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Còn ${product.stockQuantity} sản phẩm',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
          child: Row(
            children: [
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
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
                  onPressed: _isAddingToCart
                      ? null
                      : () async {
                          // Validate size đã được chọn
                          if (_selectedSize == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn size'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          // Validate quantity không vượt quá stock
                          if (_quantity > _selectedSize!.stockQuantity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Số lượng vượt quá tồn kho (Còn ${_selectedSize!.stockQuantity})',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final userId = await UserStorage.getUserId();
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng đăng nhập'),
                                backgroundColor: AppColors.error,
                              ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm vào giỏ hàng'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: AppColors.error,
                                ),
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
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
                      : const Text('Thêm Vào Giỏ'),
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
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.textPrimary,
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
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.textPrimary,
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
