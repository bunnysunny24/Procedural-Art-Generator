import 'dart:math';

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Color distribution mode
enum ColorMode {
  single,
  random,
  position,
  velocity,
  gradient,
  age
}

/// Color palette for art generation
class ColorPalette extends Equatable {
  /// List of colors in the palette
  final List<Color> colors;
  
  /// Color mode determines how colors are applied
  final ColorMode colorMode;
  
  /// Color opacity
  final double opacity;
  
  /// Whether to blend between colors
  final bool blendColors;
  
  /// Random number generator
  static final _random = Random();
  
  const ColorPalette({
    required this.colors,
    required this.colorMode,
    required this.opacity,
    required this.blendColors,
  });
  
  /// Default color palette with basic colors
  factory ColorPalette.defaultPalette() {
    return ColorPalette(
      colors: [
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
      ],
      colorMode: ColorMode.position,
      opacity: 0.8,
      blendColors: true,
    );
  }
  
  /// Create a palette based on a preset name
  factory ColorPalette.preset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'fire':
        return ColorPalette(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.amber,
            Colors.yellow,
          ],
          colorMode: ColorMode.velocity,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'neon':
        return ColorPalette(
          colors: [
            const Color(0xFF00FFFF), // cyan
            const Color(0xFFFF00FF), // magenta
            const Color(0xFF00FF00), // bright green
            const Color(0xFFFF0099), // pink
            const Color(0xFFFFFF00), // yellow
          ],
          colorMode: ColorMode.random,
          opacity: 0.8,
          blendColors: false,
        );
        
      case 'ocean':
        return ColorPalette(
          colors: [
            const Color(0xFF0077BE), // deep blue
            const Color(0xFF5F9EA0), // cadet blue
            const Color(0xFF00FFFF), // cyan
            const Color(0xFF48D1CC), // medium turquoise
            const Color(0xFF40E0D0), // turquoise
          ],
          colorMode: ColorMode.position,
          opacity: 0.7,
          blendColors: true,
        );
        
      case 'forest':
        return ColorPalette(
          colors: [
            const Color(0xFF228B22), // forest green
            const Color(0xFF008000), // green
            const Color(0xFF90EE90), // light green
            const Color(0xFF32CD32), // lime green
            const Color(0xFF556B2F), // dark olive green
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'sunset':
        return ColorPalette(
          colors: [
            const Color(0xFFFF4500), // orange red
            const Color(0xFFFF8C00), // dark orange
            const Color(0xFFFFD700), // gold
            const Color(0xFFFF6347), // tomato
            const Color(0xFF800080), // purple
          ],
          colorMode: ColorMode.position,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'grayscale':
        return ColorPalette(
          colors: [
            Colors.white,
            Colors.grey.shade300,
            Colors.grey.shade600,
            Colors.black,
          ],
          colorMode: ColorMode.age,
          opacity: 0.7,
          blendColors: true,
        );
        
      case 'rainbow':
        return ColorPalette(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
          ],
          colorMode: ColorMode.position,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'monochrome':
        // Single color with varying brightness
        final baseColor = Colors.blue;
        return ColorPalette(
          colors: [
            baseColor.shade900,
            baseColor.shade700,
            baseColor.shade500,
            baseColor.shade300,
            baseColor.shade100,
          ],
          colorMode: ColorMode.position,
          opacity: 0.8,
          blendColors: true,
        );
        
      default:
        return ColorPalette.defaultPalette();
    }
  }
  
  /// Create a random color palette
  factory ColorPalette.random() {
    final colorSchemes = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    
    // Choose a base color
    final baseColor = colorSchemes[_random.nextInt(colorSchemes.length)];
    
    // Create a palette based on the base color
    return ColorPalette(
      colors: [
        baseColor.shade900,
        baseColor.shade700,
        baseColor.shade500,
        baseColor.shade300,
        baseColor.shade100,
      ],
      colorMode: ColorMode.values[_random.nextInt(ColorMode.values.length)],
      opacity: 0.6 + _random.nextDouble() * 0.4, // Between 0.6 and 1.0
      blendColors: _random.nextBool(),
    );
  }
  
  /// Get a random color from the palette
  Color getRandomColor() {
    if (colors.isEmpty) return Colors.white.withOpacity(opacity);
    return colors[_random.nextInt(colors.length)].withOpacity(opacity);
  }
  
  /// Get a color at a specific progress point (0.0 to 1.0)
  Color getColorAtProgress(double progress) {
    if (colors.isEmpty) return Colors.white.withOpacity(opacity);
    if (colors.length == 1) return colors.first.withOpacity(opacity);
    
    // Clamp progress to valid range
    progress = progress.clamp(0.0, 1.0);
    
    if (!blendColors) {
      // Select a discrete color based on progress
      final index = (progress * colors.length).floor();
      final clampedIndex = min(index, colors.length - 1);
      return colors[clampedIndex].withOpacity(opacity);
    } else {
      // Interpolate between colors
      final segmentCount = colors.length - 1;
      final segment = (progress * segmentCount).floor();
      final segmentProgress = (progress * segmentCount) - segment;
      
      final startColor = colors[segment];
      final endColor = colors[min(segment + 1, colors.length - 1)];
      
      return Color.lerp(startColor, endColor, segmentProgress)!.withOpacity(opacity);
    }
  }
  
  /// Create a copy with modified properties
  ColorPalette copyWith({
    List<Color>? colors,
    ColorMode? colorMode,
    double? opacity,
    bool? blendColors,
  }) {
    return ColorPalette(
      colors: colors ?? this.colors,
      colorMode: colorMode ?? this.colorMode,
      opacity: opacity ?? this.opacity,
      blendColors: blendColors ?? this.blendColors,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => c.value).toList(),
      'colorMode': colorMode.index,
      'opacity': opacity,
      'blendColors': blendColors,
    };
  }
  
  /// Create from JSON map
  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    final List<dynamic> colorValues = json['colors'] as List<dynamic>? ?? [];
    final List<Color> colors = colorValues
        .map((c) => Color(c as int))
        .toList();
    
    return ColorPalette(
      colors: colors.isEmpty ? [Colors.blue, Colors.cyan] : colors,
      colorMode: ColorMode.values[json['colorMode'] as int? ?? 0],
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.8,
      blendColors: json['blendColors'] as bool? ?? true,
    );
  }
  
  @override
  List<Object?> get props => [colors, colorMode, opacity, blendColors];
}