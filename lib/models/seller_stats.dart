class SellerStats {
  final double overallRating;
  final int totalReviewCount;
  final int totalProducts;
  final int activeProducts;

  SellerStats({
    required this.overallRating,
    required this.totalReviewCount,
    required this.totalProducts,
    required this.activeProducts,
  });

  factory SellerStats.empty() {
    return SellerStats(
      overallRating: 0.0,
      totalReviewCount: 0,
      totalProducts: 0,
      activeProducts: 0,
    );
  }
}
