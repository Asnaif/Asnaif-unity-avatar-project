import 'package:flutter/material.dart';

class SmoothScrollPhysics extends AlwaysScrollableScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,
    stiffness: 100.0,
    damping: 0.8,
  );
}

class BouncyScrollPhysics extends BouncingScrollPhysics {
  const BouncyScrollPhysics({super.parent});

  @override
  BouncyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BouncyScrollPhysics(parent: buildParent(ancestor));
  }
}