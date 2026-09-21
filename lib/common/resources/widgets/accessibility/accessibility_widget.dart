import 'package:flutter/material.dart';

class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final bool? isButton;
  final bool? isHeader;
  final bool? isImage;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.isButton,
    this.isHeader,
    this.isImage,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton ?? false,
      header: isHeader ?? false,
      image: isImage ?? false,
      child: child,
    );
  }
}