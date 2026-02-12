class SpecialOffer {
  final int offerId;
  final String title;
  final int discountPercent;
  final String timeRange;
  final String? productName;
  final String? imageUrl;

  SpecialOffer({
    required this.offerId,
    required this.title,
    required this.discountPercent,
    required this.timeRange,
    this.productName,
    this.imageUrl,
  });
}
