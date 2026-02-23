import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../products/data/mock_data/mock_products.dart';
import '../../../products/domain/entities/special_offer.dart';

class SpecialOffersSection extends StatelessWidget {
  const SpecialOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Special Offers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MockProducts.specialOffers.length,
                itemBuilder: (context, index) {
                  final offer = MockProducts.specialOffers[index];
                  return SpecialOfferCard(offer: offer);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialOfferCard extends StatelessWidget {
  final SpecialOffer offer;

  const SpecialOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(child: CustomPaint(painter: PawPrintPainter())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${offer.discountPercent}% Off',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.timeRange,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Order Now'),
                ),
              ],
            ),
          ),
          // Cat image on right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
                child: offer.imageUrl != null
                    ? Image.network(
                        offer.imageUrl!,
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
                            size: 60,
                            color: AppColors.primary,
                          );
                        },
                      )
                    : const Icon(
                        Icons.pets,
                        size: 60,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PawPrintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw paw prints
    final pawSize = 20.0;
    final positions = [
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.85, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.5),
    ];

    for (final pos in positions) {
      // Main pad
      canvas.drawCircle(pos, pawSize, paint);
      // Toes
      canvas.drawCircle(
        Offset(pos.dx - pawSize * 0.5, pos.dy - pawSize * 0.8),
        pawSize * 0.4,
        paint,
      );
      canvas.drawCircle(
        Offset(pos.dx + pawSize * 0.5, pos.dy - pawSize * 0.8),
        pawSize * 0.4,
        paint,
      );
      canvas.drawCircle(
        Offset(pos.dx - pawSize * 0.3, pos.dy + pawSize * 0.5),
        pawSize * 0.35,
        paint,
      );
      canvas.drawCircle(
        Offset(pos.dx + pawSize * 0.3, pos.dy + pawSize * 0.5),
        pawSize * 0.35,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
