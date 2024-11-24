// route_transitions.dart
import 'package:flutter/material.dart';

enum TransitionType { fade, slide, scale, rotation }

Route createRoute(Widget page, {TransitionType type = TransitionType.fade}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case TransitionType.slide:
          const begin = Offset(1.0, 0.0); // From right to left
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        case TransitionType.scale:
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        case TransitionType.rotation:
          return RotationTransition(
            turns: animation,
            child: child,
          );
        case TransitionType.fade:
        default:
          return FadeTransition(
            opacity: animation,
            child: child,
          );
      }
    },
  );
}
