// lib/core/animations/page_transitions.dart
import 'package:flutter/material.dart';

class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({required this.page, this.direction = SlideDirection.right})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = direction == SlideDirection.right
                ? const Offset(1.0, 0.0)
                : direction == SlideDirection.left
                    ? const Offset(-1.0, 0.0)
                    : direction == SlideDirection.up
                        ? const Offset(0.0, 1.0)
                        : const Offset(0.0, -1.0);
            
            var end = Offset.zero;
            var curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeInOut;
            var curveTween = CurveTween(curve: curve);
            
            return FadeTransition(
              opacity: animation.drive(curveTween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class ScalePageRoute extends PageRouteBuilder {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeOutBack;
            var curveTween = CurveTween(curve: curve);
            
            return ScaleTransition(
              scale: animation.drive(curveTween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

enum SlideDirection {
  right,
  left,
  up,
  down,
}