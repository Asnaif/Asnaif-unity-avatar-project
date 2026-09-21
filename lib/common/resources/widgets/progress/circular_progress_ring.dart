import 'package:flutter/material.dart';

class CircularProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final String? label;
  final double strokeWidth;
  final Widget? centerWidget;

  const CircularProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.color = Colors.blue,
    this.label,
    this.strokeWidth = 8,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (centerWidget != null)
                centerWidget!
              else if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class LinearProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const LinearProgressBar({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: backgroundColor ?? color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
    );
  }
}