import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

enum BadgeStatus { active, inactive, pending, completed, cancelled, processing }

/// Final Earthy Artisan Design System - Status Badge Component
class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customLabel ?? config.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: config.textColor,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case BadgeStatus.active:
        return _StatusConfig(
          label: 'Active',
          backgroundColor: AppColors.success.withOpacity(0.15),
          textColor: AppColors.success,
        );
      case BadgeStatus.inactive:
        return _StatusConfig(
          label: 'Inactive',
          backgroundColor: AppColors.textSecondary.withOpacity(0.15),
          textColor: AppColors.textSecondary,
        );
      case BadgeStatus.pending:
        return _StatusConfig(
          label: 'Pending',
          backgroundColor: AppColors.warning.withOpacity(0.15),
          textColor: AppColors.warning,
        );
      case BadgeStatus.completed:
        return _StatusConfig(
          label: 'Completed',
          backgroundColor: AppColors.success.withOpacity(0.15),
          textColor: AppColors.success,
        );
      case BadgeStatus.cancelled:
        return _StatusConfig(
          label: 'Cancelled',
          backgroundColor: AppColors.error.withOpacity(0.15),
          textColor: AppColors.error,
        );
      case BadgeStatus.processing:
        return _StatusConfig(
          label: 'Processing',
          backgroundColor: AppColors.lightSageTint,
          textColor: AppColors.mutedForestGreen,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
