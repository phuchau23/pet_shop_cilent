import 'package:flutter/material.dart';

class CardStackCarousel extends StatefulWidget {
  final List<Widget> children;
  final double cardHeight;
  final double cardWidth;
  final double stackOffset;
  final double scaleFactor;

  const CardStackCarousel({
    super.key,
    required this.children,
    this.cardHeight = 360,
    this.cardWidth = 300,
    this.stackOffset = 24,
    this.scaleFactor = 0.08,
  });

  @override
  State<CardStackCarousel> createState() => _CardStackCarouselState();
}

class _CardStackCarouselState extends State<CardStackCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.88,
    );
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

    // Chỉ hiển thị tối đa 3 cards trong stack
    final visibleCards = widget.children.length > 3 ? 3 : widget.children.length;
    final stackHeight = widget.cardHeight + (visibleCards - 1) * widget.stackOffset;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render cards chồng lên nhau (từ sau ra trước)
          ...List.generate(visibleCards, (i) {
            final cardIndex = _currentIndex + i;
            if (cardIndex >= widget.children.length) return const SizedBox.shrink();
            return _buildStackedCard(cardIndex, i);
          }),
          // PageView để handle swipe
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
        ],
      ),
    );
  }

  Widget _buildStackedCard(int index, int stackPosition) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        if (!_pageController.hasClients) {
          // Hiển thị card ban đầu khi chưa có clients
          return _buildCardPlaceholder(index, stackPosition);
        }

        final page = _pageController.page ?? _currentIndex.toDouble();
        final offset = index - page;
        final absOffset = offset.abs().clamp(0.0, 2.0);

        // Tính toán scale, offset và opacity cho card
        double scale = 1.0;
        double yOffset = 0.0;
        double opacity = 1.0;
        double rotation = 0.0;

        if (stackPosition == 0) {
          // Card hiện tại (front)
          scale = 1.0 - (absOffset * widget.scaleFactor * 0.5);
          yOffset = 0.0;
          opacity = 1.0 - (absOffset * 0.2).clamp(0.0, 0.4);
          rotation = offset * 0.02; // Subtle rotation khi swipe
        } else {
          // Cards phía sau
          scale = 1.0 - (stackPosition * widget.scaleFactor);
          yOffset = stackPosition * widget.stackOffset;
          opacity = 1.0 - (stackPosition * 0.25).clamp(0.0, 0.5);
          rotation = 0.0;
        }

        return Positioned(
          left: 0,
          right: 0,
          top: yOffset,
          bottom: 0,
          child: Center(
            child: Transform.scale(
              scale: scale.clamp(0.85, 1.0),
              child: Transform.rotate(
                angle: rotation,
                child: Opacity(
                  opacity: opacity.clamp(0.4, 1.0),
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

  Widget _buildCardPlaceholder(int index, int stackPosition) {
    double scale = 1.0 - (stackPosition * widget.scaleFactor);
    double yOffset = stackPosition * widget.stackOffset;
    double opacity = 1.0 - (stackPosition * 0.25).clamp(0.0, 0.5);

    return Positioned(
      left: 0,
      right: 0,
      top: yOffset,
      bottom: 0,
      child: Center(
        child: Transform.scale(
          scale: scale.clamp(0.85, 1.0),
          child: Opacity(
            opacity: opacity.clamp(0.4, 1.0),
            child: SizedBox(
              width: widget.cardWidth,
              height: widget.cardHeight,
              child: widget.children[index],
            ),
          ),
        ),
      ),
    );
  }
}
