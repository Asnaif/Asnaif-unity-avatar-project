import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';

class EnhancedRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  const EnhancedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Styles.primaryColor,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: 3,
      displacement: 40,
      edgeOffset: 20,
      child: child,
    );
  }
}