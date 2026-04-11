import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_section.dart';
import '../pages/promo_codes_page.dart';

class HeroBannerSection extends StatelessWidget {
  const HeroBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedSection(
        delay: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 15, 20, 24),
          child: Stack(
            children: [
              // Banner image - main content
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset(
                    'assets/images/sections_sale.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                              AppColors.primaryDark,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // CTA Button overlay - bottom left, compact width
              Positioned(
                bottom: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const PromoCodesPage(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: 0,
                      left: 5,
                      right: 0,
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'Khám phá ngay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.2,
                      ),
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
