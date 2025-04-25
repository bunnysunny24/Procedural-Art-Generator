import 'package:flutter/material.dart';

/// Application-wide animation constants
class AppAnimations {
  // Durations
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 800);
  
  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasizedAccelerate = Curves.easeIn;
  static const Curve emphasizedDecelerate = Curves.easeOut;
  static const Curve energetic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve gentle = Curves.easeInOutSine;
  
  // Page transition animations
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }
  
  static PageRouteBuilder<T> slideTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }
  
  // Staggered animations (timing values for multi-part animations)
  static const double staggerValue = 0.05;
  
  static List<Interval> staggeredIntervals(int count) {
    final List<Interval> intervals = [];
    for (int i = 0; i < count; i++) {
      final start = i * staggerValue;
      intervals.add(Interval(start, start + 0.8, curve: standard));
    }
    return intervals;
  }
  
  // PresetAnimations for particle systems
  static const particleFadeInDuration = Duration(milliseconds: 800);
  static const particleMovementSpeed = 1.0; // Base movement speed multiplier
}