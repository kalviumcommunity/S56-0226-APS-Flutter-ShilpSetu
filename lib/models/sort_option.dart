enum SortOption {
  newest,
  priceLowHigh,
  priceHighLow,
  highestRated,
}

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
      case SortOption.highestRated:
        return 'Highest Rated';
    }
  }

  String get shortLabel {
    switch (this) {
      case SortOption.newest:
        return 'Newest';
      case SortOption.priceLowHigh:
        return 'Price ↑';
      case SortOption.priceHighLow:
        return 'Price ↓';
      case SortOption.highestRated:
        return 'Top Rated';
    }
  }
}
