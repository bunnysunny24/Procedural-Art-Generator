import 'dart:math';
import 'package:flutter/material.dart';
import 'color_mode.dart';

class ColorPalette {
  final ColorMode colorMode;
  final List<Color> colors;
  final double opacity;

  const ColorPalette({
    this.colorMode = ColorMode.single,
    required this.colors,
    this.opacity = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'colorMode': colorMode.index,
      'colors': colors.map((c) => c.value).toList(),
      'opacity': opacity,
    };
  }

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      colorMode: ColorMode.values[json['colorMode'] as int],
      colors: (json['colors'] as List<dynamic>)
          .map((c) => Color(c as int))
          .toList(),
      opacity: json['opacity'] as double,
    );
  }

  Color getColorAtProgress(double progress) {
    if (colors.isEmpty) return Colors.white;
    if (colors.length == 1) return colors.first;

    final segment = 1.0 / (colors.length - 1);
    final index = (progress / segment).floor();
    final remainder = (progress - (index * segment)) / segment;

    if (index >= colors.length - 1) return colors.last;
    
    return Color.lerp(colors[index], colors[index + 1], remainder) ?? colors[index];
  }

  Color getRandomColor() {
    if (colors.isEmpty) return Colors.white;
    return colors[Random().nextInt(colors.length)];
  }
}