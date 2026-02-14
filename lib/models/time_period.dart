/// Enum representing time period filters for analytics
enum TimePeriod {
  last7Days,
  last30Days,
  allTime;

  /// Returns display label for the time period
  String get label {
    switch (this) {
      case TimePeriod.last7Days:
        return 'Last 7 Days';
      case TimePeriod.last30Days:
        return 'Last 30 Days';
      case TimePeriod.allTime:
        return 'All Time';
    }
  }

  /// Returns the start date for filtering
  /// Returns null for allTime (no filtering)
  DateTime? get startDate {
    switch (this) {
      case TimePeriod.last7Days:
        return DateTime.now().subtract(const Duration(days: 7));
      case TimePeriod.last30Days:
        return DateTime.now().subtract(const Duration(days: 30));
      case TimePeriod.allTime:
        return null;
    }
  }
}
