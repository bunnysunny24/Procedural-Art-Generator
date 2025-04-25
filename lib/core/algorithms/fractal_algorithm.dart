import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'generative_algorithm.dart';
import '../models/parameter_set.dart';

/// Implementation of a fractal algorithm (Mandelbrot/Julia sets)
class FractalAlgorithm extends GenerativeAlgorithm {
  /// Image cache for the fractal rendering
  ui.Image? _fractalImage;
  
  /// Current view position in the complex plane
  late double _centerX;
  late double _centerY;
  
  /// Current zoom level
  late double _zoom;
  
  /// Number of iterations for fractal calculation
  late int _maxIterations;
  
  /// Whether the fractal needs to be redrawn
  bool _needsRedraw = true;
  
  FractalAlgorithm(super.parameters) {
    _initialize();
  }
  
  void _initialize() {
    // Get parameters or use defaults
    final specificParams = parameters.algorithmSpecificParams;
    
    _centerX = specificParams['centerX'] as double? ?? -0.5;
    _centerY = specificParams['centerY'] as double? ?? 0.0;
    _zoom = specificParams['zoom'] as double? ?? 4.0;
    _maxIterations = specificParams['maxIterations'] as int? ?? 100;
    
    // Mark for redraw
    _needsRedraw = true;
    _fractalImage = null;
  }
  
  @override
  void update() {
    // Fractal algorithms typically don't need frame-by-frame updates
    // unless implementing animations or interactive exploration
    if (interactionPoint != null && parameters.interactionEnabled) {
      // Convert screen coordinates to complex plane coordinates
      _handleInteraction();
    }
  }
  
  void _handleInteraction() {
    if (interactionPoint == null) return;
    
    final width = parameters.canvasSize.width;
    final height = parameters.canvasSize.height;
    
    // Map screen coordinates to complex plane
    final dx = interactionPoint!.dx - width / 2;
    final dy = interactionPoint!.dy - height / 2;
    
    // Adjust center based on interaction
    _centerX += dx * 0.01 / _zoom;
    _centerY += dy * 0.01 / _zoom;
    
    // Mark for redraw
    _needsRedraw = true;
  }
  
  @override
  void render(Canvas canvas) {
    final width = parameters.canvasSize.width.toInt();
    final height = parameters.canvasSize.height.toInt();
    
    // Generate fractal image if needed
    if (_needsRedraw || _fractalImage == null) {
      _generateFractalImage(width, height);
      _needsRedraw = false;
    }
    
    // Draw fractal image
    if (_fractalImage != null) {
      canvas.drawImage(_fractalImage!, Offset.zero, Paint());
    }
    
    // Draw debug information if enabled
    if (parameters.algorithmSpecificParams['showDebugInfo'] == true) {
      _drawDebugInfo(canvas);
    }
  }
  
  Future<void> _generateFractalImage(int width, int height) async {
    // For this placeholder implementation, we'll just draw a simple pattern
    // In a real implementation, you would compute the actual fractal
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Create a background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Draw a simple pattern simulating a fractal
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;
      
    final fractalType = parameters.algorithmSpecificParams['fractalType'] ?? 'mandelbrot';
    final centerX = width / 2;
    final centerY = height / 2;
    
    for (int x = 0; x < width; x += 2) {
      for (int y = 0; y < height; y += 2) {
        // Map pixel coordinates to complex plane
        final real = (x - centerX) / (width / 4) / _zoom + _centerX;
        final imag = (y - centerY) / (height / 4) / _zoom + _centerY;
        
        // Simple iteration count simulation
        int iterations;
        if (fractalType == 'julia') {
          iterations = _simulateJuliaIteration(real, imag);
        } else {
          iterations = _simulateMandelbrotIteration(real, imag);
        }
        
        // Map iterations to color
        final progress = iterations / _maxIterations;
        final color = _getColorForIteration(progress);
        
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 2, 2),
          paint,
        );
      }
    }
    
    // Create image from canvas
    final picture = recorder.endRecording();
    _fractalImage = await picture.toImage(width, height);
  }
  
  /// Simulate Mandelbrot iteration count (placeholder implementation)
  int _simulateMandelbrotIteration(double real, double imag) {
    // Simple placeholder that creates a pattern
    // This is NOT a real Mandelbrot calculation, just a visual approximation
    final dist = sqrt(real * real + imag * imag);
    final angle = atan2(imag, real);
    
    return ((sin(dist * 10 + _zoom) * cos(angle * 5) * 0.5 + 0.5) * _maxIterations).toInt();
  }
  
  /// Simulate Julia set iteration count (placeholder implementation)
  int _simulateJuliaIteration(double real, double imag) {
    // Simple placeholder that creates a pattern
    // This is NOT a real Julia calculation, just a visual approximation
    final dist = sqrt(real * real + imag * imag);
    final angle = atan2(imag, real);
    
    return ((cos(dist * 8 + _zoom) * sin(angle * 3) * 0.5 + 0.5) * _maxIterations).toInt();
  }
  
  /// Get color for iteration count
  Color _getColorForIteration(double progress) {
    // Use color palette
    return parameters.colorPalette.getColorAtProgress(progress);
  }
  
  void _drawDebugInfo(Canvas canvas) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Zoom: ${_zoom.toStringAsFixed(2)}\n'
            'Center: (${_centerX.toStringAsFixed(3)}, ${_centerY.toStringAsFixed(3)})',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }
  
  @override
  void reset() {
    _initialize();
  }
  
  @override
  void updateParameters(ParameterSet newParameters) {
    final oldParams = parameters;
    parameters = newParameters;
    
    if (oldParams.canvasSize != newParameters.canvasSize ||
        oldParams.algorithmSpecificParams['fractalType'] != newParameters.algorithmSpecificParams['fractalType'] ||
        oldParams.algorithmSpecificParams['maxIterations'] != newParameters.algorithmSpecificParams['maxIterations']) {
      _initialize();
    }
  }
  
  @override
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  @override
  Future<ui.Image?> createPreview(Size size) async {
    // Implementation will depend on how you plan to use previews
    return null;
  }
}