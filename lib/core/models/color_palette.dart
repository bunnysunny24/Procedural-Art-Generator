import 'dart:math';
import 'package:flutter/material.dart';

/// Defines how colors are selected from a palette
enum ColorMode {
  /// Colors are selected randomly from the palette
  random,
  
  /// Colors are selected based on position/progress
  position,
  
  /// Colors are interpolated based on some parameter
  gradient
}

/// Represents a color palette for generative art
class ColorPalette {
  /// List of colors in this palette
  final List<Color> colors;
  
  /// The mode for selecting colors from this palette
  final ColorMode colorMode;
  
  /// Random number generator for color selection
  final Random _random = Random();
  
  /// Creates a new color palette with the given colors and mode
  ColorPalette({
    required this.colors,
    this.colorMode = ColorMode.gradient,
  }) : assert(colors.isNotEmpty, 'Color palette must contain at least one color');
  
  /// Returns a random color from the palette
  Color getRandomColor() {
    return colors[_random.nextInt(colors.length)];
  }
  
  /// Returns a color based on the progress (0.0 - 1.0) through the palette
  Color getColorAtProgress(double progress) {
    if (colors.length == 1) return colors[0];
    
    // Clamp progress to 0.0 - 1.0
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Calculate which colors to interpolate between
    final segmentCount = colors.length - 1;
    final segmentLength = 1.0 / segmentCount;
    final segmentIndex = (clampedProgress / segmentLength).floor();
    
    // Ensure we don't go out of bounds
    final safeIndex = segmentIndex.clamp(0, segmentCount - 1);
    
    // Calculate progress within this segment
    final segmentProgress = (clampedProgress - (safeIndex * segmentLength)) / segmentLength;
    
    // Interpolate between the two colors
    return Color.lerp(colors[safeIndex], colors[safeIndex + 1], segmentProgress)!;
  }
}