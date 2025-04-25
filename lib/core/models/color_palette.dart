import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Defines different modes for applying colors to particles/elements
enum ColorMode {
  single,        // Single color
  gradient,      // Gradient between colors
  random,        // Random color from palette
  position,      // Color based on position
  velocity,      // Color based on velocity
  age,           // Color changing with particle age
  custom         // Custom coloring logic
}

/// Represents a color palette for art generation
class ColorPalette extends Equatable {
  /// Primary colors in the palette
  final List<Color> colors;
  
  /// Optional gradient stops for gradient mode
  final List<double>? gradientStops;
  
  /// Color mode for applying colors to particles/elements
  final ColorMode colorMode;
  
  /// Color opacity/alpha
  final double opacity;
  
  /// Whether to use color blending between particles
  final bool blendColors;
  
  /// Additional settings for custom color behavior
  final Map<String, dynamic> customSettings;

  const ColorPalette({
    required this.colors,
    this.gradientStops,
    required this.colorMode,
    required this.opacity,
    required this.blendColors,
    this.customSettings = const {},
  });
  
  /// Creates a default color palette
  factory ColorPalette.defaultPalette() {
    return ColorPalette(
      colors: [
        Colors.blue,
        Colors.purple,
        Colors.red,
        Colors.orange,
        Colors.yellow,
      ],
      colorMode: ColorMode.gradient,
      opacity: 0.8,
      blendColors: true,
    );
  }
  
  /// Creates predefined color schemes
  factory ColorPalette.preset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'fire':
        return ColorPalette(
          colors: [
            const Color(0xFFFFD700),  // Gold
            const Color(0xFFFFA500),  // Orange
            const Color(0xFFFF4500),  // OrangeRed
            const Color(0xFFDC143C),  // Crimson
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'ocean':
        return ColorPalette(
          colors: [
            const Color(0xFF00FFFF),  // Cyan
            const Color(0xFF1E90FF),  // DodgerBlue
            const Color(0xFF4169E1),  // RoyalBlue
            const Color(0xFF000080),  // Navy
            const Color(0xFF191970),  // MidnightBlue
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'forest':
        return ColorPalette(
          colors: [
            const Color(0xFF90EE90),  // LightGreen
            const Color(0xFF32CD32),  // LimeGreen
            const Color(0xFF228B22),  // ForestGreen
            const Color(0xFF006400),  // DarkGreen
            const Color(0xFF556B2F),  // DarkOliveGreen
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'sunset':
        return ColorPalette(
          colors: [
            const Color(0xFFFFD700),  // Gold
            const Color(0xFFFF8C00),  // DarkOrange
            const Color(0xFFFF4500),  // OrangeRed
            const Color(0xFF8B0000),  // DarkRed
            const Color(0xFF191970),  // MidnightBlue
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      case 'neon':
        return ColorPalette(
          colors: [
            const Color(0xFF00FFFF),  // Cyan
            const Color(0xFFFF00FF),  // Magenta
            const Color(0xFFFF0000),  // Red
            const Color(0xFF00FF00),  // Lime
            const Color(0xFFFFFF00),  // Yellow
          ],
          colorMode: ColorMode.random,
          opacity: 1.0,
          blendColors: true,
        );
        
      case 'monochrome':
        return ColorPalette(
          colors: [
            Colors.white,
            Colors.grey.shade300,
            Colors.grey.shade600,
            Colors.grey.shade900,
            Colors.black,
          ],
          colorMode: ColorMode.gradient,
          opacity: 0.8,
          blendColors: true,
        );
        
      default:
        return ColorPalette.defaultPalette();
    }
  }
  
  /// Returns a copy with modified properties
  ColorPalette copyWith({
    List<Color>? colors,
    List<double>? gradientStops,
    ColorMode? colorMode,
    double? opacity,
    bool? blendColors,
    Map<String, dynamic>? customSettings,
  }) {
    return ColorPalette(
      colors: colors ?? this.colors,
      gradientStops: gradientStops ?? this.gradientStops,
      colorMode: colorMode ?? this.colorMode,
      opacity: opacity ?? this.opacity,
      blendColors: blendColors ?? this.blendColors,
      customSettings: customSettings ?? this.customSettings,
    );
  }
  
  /// Adds a color to the palette
  ColorPalette addColor(Color color) {
    final newColors = List<Color>.from(colors)..add(color);
    return copyWith(colors: newColors);
  }
  
  /// Removes a color from the palette at the specified index
  ColorPalette removeColor(int index) {
    if (index < 0 || index >= colors.length || colors.length <= 1) {
      return this;
    }
    final newColors = List<Color>.from(colors)..removeAt(index);
    return copyWith(colors: newColors);
  }
  
  /// Returns a color based on progress (0.0 to 1.0)
  Color getColorAtProgress(double progress) {
    if (colors.isEmpty) return Colors.white;
    if (colors.length == 1) return colors.first.withOpacity(opacity);
    
    if (progress <= 0.0) return colors.first.withOpacity(opacity);
    if (progress >= 1.0) return colors.last.withOpacity(opacity);
    
    if (gradientStops != null && gradientStops!.length == colors.length) {
      // Use custom gradient stops
      for (int i = 0; i < gradientStops!.length - 1; i++) {
        if (progress >= gradientStops![i] && progress <= gradientStops![i + 1]) {
          double localProgress = (progress - gradientStops![i]) / 
              (gradientStops![i + 1] - gradientStops![i]);
          return Color.lerp(
            colors[i], 
            colors[i + 1], 
            localProgress
          )!.withOpacity(opacity);
        }
      }
      return colors.last.withOpacity(opacity);
    } else {
      // Evenly distributed colors
      final segmentCount = colors.length - 1;
      final segment = (progress * segmentCount).floor();
      final localProgress = (progress * segmentCount) - segment;
      
      return Color.lerp(
        colors[segment], 
        colors[segment + 1], 
        localProgress
      )!.withOpacity(opacity);
    }
  }
  
  /// Returns a random color from the palette
  Color getRandomColor() {
    if (colors.isEmpty) return Colors.white.withOpacity(opacity);
    if (colors.length == 1) return colors.first.withOpacity(opacity);
    
    final random = DateTime.now().millisecondsSinceEpoch % colors.length;
    return colors[random].withOpacity(opacity);
  }
  
  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => c.value).toList(),
      'gradientStops': gradientStops,
      'colorMode': colorMode.index,
      'opacity': opacity,
      'blendColors': blendColors,
      'customSettings': customSettings,
    };
  }
  
  /// Creates from JSON
  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      colors: (json['colors'] as List?)
              ?.map((c) => Color(c as int))
              .toList() ?? 
          [Colors.blue, Colors.purple],
      gradientStops: (json['gradientStops'] as List?)
              ?.map((s) => (s as num).toDouble())
              .toList(),
      colorMode: ColorMode.values[json['colorMode'] ?? 0],
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.8,
      blendColors: json['blendColors'] ?? true,
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
    );
  }
  
  @override
  List<Object?> get props => [
    colors,
    gradientStops,
    colorMode,
    opacity,
    blendColors,
    customSettings
  ];
}