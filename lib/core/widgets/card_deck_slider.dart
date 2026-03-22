import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CardDeckSlider extends StatefulWidget {
  final List<Widget> children;
  final double cardHeight;
  final double cardWidth;
  final double peekWidth;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const CardDeckSlider({
    super.key,
    required this.children,
    this.cardHeight = 360,
    this.cardWidth = 300,
    this.peekWidth = 16,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<CardDeckSlider> createState() => _CardDeckSliderState();
}

class _CardDeckSliderState extends State<CardDeckSlider> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return SizedBox(height: widget.cardHeight);
    }

    return SizedBox(
      height: widget.cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render cards chồng lên nhau
          ...widget.children.asMap().entries.map((entry) {
            final index = entry.key;
            return _buildStackedCard(index);
          }),
          // Swipe gesture handler (PageView để handle swipe)
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.children.length,
              itemBuilder: (context, index) {
                return const SizedBox.shrink(); // Invisible, chỉ để handle swipe
              },
            ),
          ),
          // Arrow indicator bên phải
          if (_currentIndex < widget.children.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kéo qua phải',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Load more button (nếu có)
          if (widget.hasMore && _currentIndex >= widget.children.length - 2)
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: widget.onLoadMore,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Xem thêm'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStackedCard(int index) {
    final isCurrent = index == _currentIndex;
    final isBehind = index > _currentIndex;
    final distance = index - _currentIndex;

    if (index < _currentIndex) {
      // Cards đã swipe qua - ẩn đi
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double xOffset = 0.0;
        double yOffset = 0.0;
        double scale = 1.0;
        double opacity = 1.0;

        if (isCurrent) {
          // Card hiện tại - full width, có thể swipe
          if (_pageController.hasClients) {
            final page = _pageController.page ?? _currentIndex.toDouble();
            final offset = index - page;
            if (offset < 0) {
              // Đang swipe card này đi (sang trái)
              xOffset = offset * widget.cardWidth;
              yOffset = (-offset * widget.cardHeight * 0.3).clamp(0.0, widget.cardHeight * 0.3);
              opacity = (1.0 + offset).clamp(0.0, 1.0);
            }
          }
        } else if (isBehind) {
          // Cards phía sau - chỉ hiện viền bên phải, scale nhỏ dần
          // distance = 1: card đầu tiên sau card hiện tại
          // distance = 2: card thứ 2 sau card hiện tại
          final peekAmount = widget.peekWidth * distance;
          xOffset = -(widget.cardWidth - peekAmount);
          scale = 1.0 - (distance * 0.05).clamp(0.0, 0.15);
          opacity = 1.0 - (distance * 0.15).clamp(0.0, 0.3);
        }

        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Transform.translate(
            offset: Offset(xOffset, yOffset),
            child: Transform.scale(
              scale: scale.clamp(0.85, 1.0),
              child: Opacity(
                opacity: opacity.clamp(0.6, 1.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    child: widget.children[index],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
