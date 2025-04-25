import 'package:flutter/material.dart';

/// Application-wide color constants
class AppColors {
  // Primary colors
  static const primary = Color(0xFF4A6FD4);
  static const secondary = Color(0xFF6E42CA);
  static const accent = Color(0xFFFF7D54);
  
  // Background colors
  static const background = Color(0xFFF9F9FB);
  static const backgroundDark = Color(0xFF1F1F29);
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF2D2D3A);
  
  // AppBar colors
  static const appBarBackground = Color(0xFFF2F2F6);
  static const appBarForeground = Color(0xFF2E3440);
  static const appBarBackgroundDark = Color(0xFF262631);
  static const appBarForegroundDark = Color(0xFFECEFF4);
  
  // Text colors
  static const textPrimary = Color(0xFF2E3440);
  static const textSecondary = Color(0xFF4C566A);
  static const textPrimaryDark = Color(0xFFECEFF4);
  static const textSecondaryDark = Color(0xFFD8DEE9);
  
  // Functional colors
  static const error = Color(0xFFBF616A);
  static const success = Color(0xFFA3BE8C);
  static const warning = Color(0xFFEBCB8B);
  static const info = Color(0xFF5E81AC);
  
  // Canvas-specific colors
  static const canvasBorder = Color(0xFFE0E0E0);
  static const canvasBorderDark = Color(0xFF3B3B4D);
  static const canvasBackground = Colors.white;
  static const canvasBackgroundDark = Color(0xFF1A1A24);
  
  // Control panel colors
  static const controlBackground = Color(0xFFF2F2F6);
  static const controlBackgroundDark = Color(0xFF282836);
  static const controlBorder = Color(0xFFE5E9F0);
  static const controlBorderDark = Color(0xFF3B4252);
  
  // Particle color presets
  static final List<Color> particleColorPresets = [
    const Color(0xFF4A6FD4), // Blue
    const Color(0xFF6E42CA), // Purple
    const Color(0xFFFF7D54), // Orange
    const Color(0xFFFF5252), // Red
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFFC107), // Yellow
    const Color(0xFF9C27B0), // Violet
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFF4081), // Pink
    const Color(0xFF607D8B), // Blue Grey
  ];
  
  // Gradient presets
  static final List<List<Color>> gradientPresets = [
    [const Color(0xFF4A6FD4), const Color(0xFF6E42CA)], // Blue to Purple
    [const Color(0xFF6E42CA), const Color(0xFFFF4081)], // Purple to Pink
    [const Color(0xFFFF7D54), const Color(0xFFFFC107)], // Orange to Yellow
    [const Color(0xFF4CAF50), const Color(0xFF00BCD4)], // Green to Cyan
    [const Color(0xFF9C27B0), const Color(0xFFFF4081)], // Violet to Pink
    [const Color(0xFF4A6FD4), const Color(0xFF00BCD4)], // Blue to Cyan
    [const Color(0xFF3D5AFE), const Color(0xFF00B0FF)], // Indigo to Light Blue
  ];
}