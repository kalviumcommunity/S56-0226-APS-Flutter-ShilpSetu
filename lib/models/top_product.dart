/// Model representing a top-selling product with sales metrics
class TopProduct {
  final String productId;
  final String title;
  final String imageUrl;
  final int unitsSold;
  final double revenue;

  TopProduct({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.unitsSold,
    required this.revenue,
  });
}
