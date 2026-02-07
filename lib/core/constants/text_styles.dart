import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.muted,
  );

  static const TextStyle body = TextStyle(fontSize: 14, color: AppColors.text);

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
