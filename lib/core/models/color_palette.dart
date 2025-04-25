import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/core/models/color_mode.dart';
import 'package:myapp/core/models/parameter_set.dart';

/// Represents a color palette for the generative art
class ColorPalette {
  /// List of colors in the palette
  final List<Color> colors;

  /// How colors should be assigned
  final ColorMode colorMode;

  /// Opacity of the colors
  final double opacity;

  /// Creates a new color palette
  const ColorPalette({
    this.colorMode = ColorMode.single,
    required this.colors,
    this.opacity = 1.0,
  });

  /// Returns a color at the given progress (0.0 - 1.0) by interpolating through the palette
  Color getColorAtProgress(double progress) {
    if (colors.isEmpty) return Colors.white;
    if (colors.length == 1) return colors.first;

    final segment = 1.0 / (colors.length - 1);
    final index = (progress / segment).floor();
    final remainder = (progress - (index * segment)) / segment;

    if (index >= colors.length - 1) return colors.last;

    return Color.lerp(colors[index], colors[index + 1], remainder) ?? colors[index];
  }

  /// Returns a random color from the palette
  Color getRandomColor() {
    if (colors.isEmpty) return Colors.white;
    return colors[Random().nextInt(colors.length)];
  }
}