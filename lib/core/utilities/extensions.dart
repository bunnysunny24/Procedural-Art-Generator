import 'dart:ui';
import 'dart:math' as math;

/// Extensions on the [Offset] class
extension OffsetExtensions on Offset {
  /// Returns a normalized version of this offset (with length of 1.0)
  /// If the offset is zero, returns Offset.zero
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }
}