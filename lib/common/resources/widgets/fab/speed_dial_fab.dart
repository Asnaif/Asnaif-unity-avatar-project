import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:interprep/common/constants/styles.dart';

class SpeedDialFAB extends StatelessWidget {
  final List<SpeedDialChild> children;
  final IconData? icon;
  final String? label;

  const SpeedDialFAB({
    super.key,
    required this.children,
    this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22),
      backgroundColor: Styles.primaryColor,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      elevation: 8,
      shape: const CircleBorder(),
      children: children,
    );
  }
}

class SpeedDialAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;

  SpeedDialAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
  });

  SpeedDialChild toWidget() {
    return SpeedDialChild(
      child: Icon(icon),
      backgroundColor: backgroundColor ?? Styles.primaryColor,
      foregroundColor: Colors.white,
      label: label,
      labelStyle: const TextStyle(fontSize: 16),
      onTap: onTap,
    );
  }
}