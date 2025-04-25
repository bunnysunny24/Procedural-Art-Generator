import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/core/models/color_mode.dart';

/// Represents a color palette for the generative art
class ColorPalette {
  /// List of colors in the palette
  final List<Color> colors;
  
  /// How colors should be assigned
  final ColorMode colorMode;
  
  /// Random number generator
  final Random _random = Random();
  
  /// Creates a new color palette
  ColorPalette({
    required this.colors, 
    this.colorMode = ColorMode.random
  });
  
  /// Creates a color palette from a list of hex strings
  factory ColorPalette.fromHexColors(List<String> hexColors, {ColorMode colorMode = ColorMode.random}) {
    return ColorPalette(
      colors: hexColors.map((hex) => _hexToColor(hex)).toList(),
      colorMode: colorMode,
    );
  }
  
  /// Returns a random color from the palette
  Color getRandomColor() {
    if (colors.isEmpty) return Colors.black;
    return colors[_random.nextInt(colors.length)];
  }
  
  /// Returns a color at the given progress (0.0 - 1.0) by interpolating through the palette
  Color getColorAtProgress(double progress) {
    if (colors.isEmpty) return Colors.black;
    if (colors.length == 1) return colors.first;
    
    // Clamp progress between 0 and 1
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Calculate the position in the color array
    final position = clampedProgress * (colors.length - 1);
    final index = position.floor();
    
    // If we're exactly on a color, return it
    if (position == index.toDouble()) return colors[index];
    
    // Otherwise interpolate between the two closest colors
    final nextIndex = index + 1;
    final colorWeight = position - index;
    
    return Color.lerp(colors[index], colors[nextIndex], colorWeight)!;
  }
  
  /// Converts a hex string to a Color
  static Color _hexToColor(String hexString) {
    final hex = hexString.replaceAll('#', '');
    
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    } else if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    } else {
      // Default to black for invalid hex
      return Colors.black;
    }
  }
}