import 'package:flutter/material.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? decorationColor;

  const CustomTooltip({
    super.key,
    required this.message,
    required this.child,
    this.padding,
    this.textStyle,
    this.decorationColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: textStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: BoxDecoration(
        color: decorationColor ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      preferBelow: false,
      verticalOffset: 10,
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}