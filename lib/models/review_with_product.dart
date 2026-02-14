/// Model representing a review with associated product information
/// Used for admin review moderation
class ReviewWithProduct {
  final String reviewId;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String buyerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewWithProduct({
    required this.reviewId,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
