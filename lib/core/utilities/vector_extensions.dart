import 'package:flutter/material.dart';

/// Extensions for the Offset class to add vector functionality
extension OffsetExtensions on Offset {
  /// Returns a normalized version of this vector (magnitude of 1)
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return this / magnitude;
  }
  
  /// Returns a new vector scaled by the given factor
  Offset operator *(double factor) {
    return Offset(dx * factor, dy * factor);
  }

  /// Returns a new vector divided by the given factor
  Offset operator /(double factor) {
    return Offset(dx / factor, dy / factor);
  }
}