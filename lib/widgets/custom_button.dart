import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const CustomButton(
      {Key? key, required this.label, this.onPressed, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          elevation: 0,
        ),
        child: Text(label, style: AppTextStyles.button),
      ),
    );
  }
}
