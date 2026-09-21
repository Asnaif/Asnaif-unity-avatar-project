import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwipeableCard extends StatelessWidget {
  final Widget child;
  final List<SwipeAction>? startActions;
  final List<SwipeAction>? endActions;
  final VoidCallback? onTap;

  const SwipeableCard({
    super.key,
    required this.child,
    this.startActions,
    this.endActions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if ((startActions == null || startActions!.isEmpty) &&
        (endActions == null || endActions!.isEmpty)) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return Slidable(
      startActionPane: startActions != null && startActions!.isNotEmpty
          ? ActionPane(
              motion: const DrawerMotion(),
              children: startActions!.map((action) => action.toWidget()).toList(),
            )
          : null,
      endActionPane: endActions != null && endActions!.isNotEmpty
          ? ActionPane(
              motion: const DrawerMotion(),
              children: endActions!.map((action) => action.toWidget()).toList(),
            )
          : null,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class SwipeAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  Widget toWidget() {
    return SlidableAction(
      onPressed: (_) => onPressed(),
      backgroundColor: color,
      icon: icon,
      label: label,
      borderRadius: BorderRadius.circular(12),
    );
  }
}