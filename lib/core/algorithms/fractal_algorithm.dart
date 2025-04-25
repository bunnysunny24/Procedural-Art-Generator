import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/parameter_set.dart';
import '../models/color_palette.dart';
import 'generative_algorithm.dart';

/// Implementation of fractal-based generative algorithm
class FractalAlgorithm extends GenerativeAlgorithm {
  /// Available fractal types
  enum FractalType {
    mandelbrot,
    julia,
    burningShip,
    tricorn,
    multibrot,
  }
  
  /// Current fractal type
  late FractalType _fractalType;
  
  /// Maximum iterations for calculation
  late int _maxIterations;
  
  /// View bounds in the complex plane
  late Rect _bounds;
  
  /// Julia set parameter (for Julia fractals)
  late Complex _juliaC;
  
  /// Multibrot power parameter
  late double _multiPower;
  
  /// Cached image for rendering optimization
  ui.Image? _cachedImage;
  
  /// Current interaction point
  Offset? _interactionPoint;
  
  /// Whether interaction is currently active
  bool _interactionActive = false;
  
  /// Current zoom level
  double _zoomLevel = 1.0;
  
  /// Complex number class for fractal calculations
  class Complex {
    final double re;  // Real part
    final double im;  // Imaginary part
    
    const Complex(this.re, this.im);
    
    Complex operator +(Complex other) => Complex(re + other.re, im + other.im);
    Complex operator -(Complex other) => Complex(re - other.re, im - other.im);
    Complex operator *(Complex other) => Complex(
      re * other.re - im * other.im,
      re * other.im + im * other.re,
    );
    
    Complex pow(double n) {
      if (re == 0 && im == 0) return Complex(0, 0);
      
      final r = sqrt(re * re + im * im);
      final theta = atan2(im, re);
      final newR = pow(r, n);
      final newTheta = theta * n;
      
      return Complex(
        newR * cos(newTheta),
        newR * sin(newTheta),
      );
    }
    
    double magnitudeSquared() => re * re + im * im;
    double magnitude() => sqrt(magnitudeSquared());
  }

  FractalAlgorithm(super.parameters) {
    initialize();
  }

  @override
  void initialize() {
    _initializeFromParameters();
    _generateFractalImage();
  }
  
  /// Initialize fractal parameters from algorithm settings
  void _initializeFromParameters() {
    final specificParams = parameters.algorithmSpecificParams;
    
    // Determine fractal type
    final fractalTypeIndex = specificParams['fractalType'] as int? ?? 0;
    _fractalType = FractalType.values[fractalTypeIndex.clamp(0, FractalType.values.length - 1)];
    
    // Get max iterations (higher = more detail but slower)
    _maxIterations = specificParams['maxIterations'] as int? ?? 100;
    
    // Set view bounds (default to classic Mandelbrot view)
    _bounds = Rect.fromLTRB(
      specificParams['minX'] as double? ?? -2.5,
      specificParams['minY'] as double? ?? -1.5,
      specificParams['maxX'] as double? ?? 1.5, 
      specificParams['maxY'] as double? ?? 1.5,
    );
    
    // Julia set parameters
    _juliaC = Complex(
      specificParams['juliaRe'] as double? ?? -0.7,
      specificParams['juliaIm'] as double? ?? 0.27,
    );
    
    // Multibrot power parameter
    _multiPower = specificParams['multiPower'] as double? ?? 3.0;
    
    // Reset zoom
    _zoomLevel = 1.0;
  }
  
  /// Generate the fractal image
  Future<void> _generateFractalImage() async {
    final width = parameters.canvasSize.width.toInt();
    final height = parameters.canvasSize.height.toInt();
    
    // Create a pixel buffer for the image
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Calculate and draw fractal
    _renderFractalDirect(canvas, Size(width.toDouble(), height.toDouble()));
    
    // Complete the picture
    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage(width, height);
  }
  
  /// Directly render the fractal to canvas (slow but simpler implementation)
  void _renderFractalDirect(Canvas canvas, Size size) {
    final width = size.width.toInt();
    final height = size.height.toInt();
    
    // For pixel-perfect rendering, draw individual pixels
    final pixelPaint = Paint();
    
    // Apply scaling based on zoom level
    final boundWidth = _bounds.width / _zoomLevel;
    final boundHeight = _bounds.height / _zoomLevel;
    final boundCenterX = (_bounds.left + _bounds.right) / 2;
    final boundCenterY = (_bounds.top + _bounds.bottom) / 2;
    
    final adjustedBounds = Rect.fromLTRB(
      boundCenterX - boundWidth / 2,
      boundCenterY - boundHeight / 2,
      boundCenterX + boundWidth / 2,
      boundCenterY + boundHeight / 2,
    );
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Map pixel coordinate to complex plane
        final re = adjustedBounds.left + (x / width) * adjustedBounds.width;
        final im = adjustedBounds.top + (y / height) * adjustedBounds.height;
        
        // Calculate fractal value at this point
        final iterations = _calculateFractal(Complex(re, im));
        
        // Skip points that are in the set (reached max iterations)
        if (iterations >= _maxIterations) {
          continue;
        }
        
        // Color based on iteration count
        final color = _getColorForIteration(iterations);
        pixelPaint.color = color;
        
        // Draw pixel
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          pixelPaint,
        );
      }
    }
  }
  
  /// Calculate fractal iterations for a point in the complex plane
  int _calculateFractal(Complex c) {
    Complex z;
    Complex c2; // Will be used for Julia sets
    
    // Different initialization depending on fractal type
    switch (_fractalType) {
      case FractalType.mandelbrot:
        z = Complex(0, 0);
        c2 = c;
        break;
      case FractalType.julia:
        z = c;
        c2 = _juliaC;
        break;
      case FractalType.burningShip:
        z = Complex(0, 0);
        c2 = c;
        break;
      case FractalType.tricorn:
        z = Complex(0, 0);
        c2 = c;
        break;
      case FractalType.multibrot:
        z = Complex(0, 0);
        c2 = c;
        break;
    }
    
    int iterations = 0;
    final escapeRadius = 4.0; // Escape radius squared
    
    while (iterations < _maxIterations && z.magnitudeSquared() < escapeRadius) {
      switch (_fractalType) {
        case FractalType.mandelbrot:
          z = z * z + c2;
          break;
        case FractalType.julia:
          z = z * z + c2;
          break;
        case FractalType.burningShip:
          // Take absolute values before squaring
          z = Complex(abs(z.re), abs(z.im)) * Complex(abs(z.re), abs(z.im)) + c2;
          break;
        case FractalType.tricorn:
          // Complex conjugate before squaring
          z = Complex(z.re, -z.im) * Complex(z.re, -z.im) + c2;
          break;
        case FractalType.multibrot:
          // Higher power
          z = z.pow(_multiPower) + c2;
          break;
      }
      iterations++;
    }
    
    return iterations;
  }
  
  /// Get color for a specific iteration count
  Color _getColorForIteration(int iterations) {
    final colorPalette = parameters.colorPalette;
    
    if (iterations >= _maxIterations) {
      return Colors.black;
    }
    
    // Normalize iteration count
    final progress = iterations / _maxIterations.toDouble();
    
    switch (colorPalette.colorMode) {
      case ColorMode.single:
        return colorPalette.colors.isNotEmpty 
            ? colorPalette.colors.first
            : Colors.white;
            
      case ColorMode.gradient:
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.position:
        // Create banded effect
        final cyclicProgress = (progress * 10) % 1.0;
        return colorPalette.getColorAtProgress(cyclicProgress);
        
      default:
        return colorPalette.getColorAtProgress(progress);
    }
  }

  @override
  void update() {
    // Most fractal updates happen on interaction
    // No animation by default
  }

  @override
  void render(Canvas canvas, Size size) {
    // If we have a cached image, draw it
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    } else {
      // Fallback if image is not yet generated
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = parameters.backgroundColor,
      );
    }
    
    // Draw interaction indicator if active
    if (parameters.interactionEnabled && _interactionPoint != null && _interactionActive) {
      canvas.drawCircle(
        _interactionPoint!,
        10.0,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  void handleInteraction(Offset? position, bool isPressed) {
    if (position == null) return;
    
    _interactionPoint = position;
    _interactionActive = isPressed;
    
    if (isPressed && parameters.interactionEnabled) {
      // For Julia sets, interactive parameter setting
      if (_fractalType == FractalType.julia) {
        // Map screen position to complex plane
        final re = _bounds.left + (position.dx / parameters.canvasSize.width) * _bounds.width;
        final im = _bounds.top + (position.dy / parameters.canvasSize.height) * _bounds.height;
        
        // Update Julia parameter
        _juliaC = Complex(re, im);
        
        // Regenerate image
        _generateFractalImage();
      } else {
        // For other fractals, zoom centered on the interaction point
        _zoomAtPoint(position, isPressed);
      }
    }
  }
  
  /// Zoom in or out centered on a specific point
  void _zoomAtPoint(Offset position, bool zoomIn) {
    // Map screen position to complex plane position
    final boundWidth = _bounds.width / _zoomLevel;
    final boundHeight = _bounds.height / _zoomLevel;
    final boundCenterX = (_bounds.left + _bounds.right) / 2;
    final boundCenterY = (_bounds.top + _bounds.bottom) / 2;
    
    final pointX = boundCenterX - boundWidth / 2 + (position.dx / parameters.canvasSize.width) * boundWidth;
    final pointY = boundCenterY - boundHeight / 2 + (position.dy / parameters.canvasSize.height) * boundHeight;
    
    // Adjust zoom level
    if (zoomIn) {
      _zoomLevel *= 1.2; // Zoom in
    } else {
      _zoomLevel /= 1.2; // Zoom out
    }
    
    // Regenerate with new zoom level
    _generateFractalImage();
  }

  @override
  void reset() {
    // Reset zoom and position
    _zoomLevel = 1.0;
    _initializeFromParameters();
    _generateFractalImage();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    final needsRegeneration = 
        parameters.canvasSize != newParameters.canvasSize ||
        parameters.colorPalette != newParameters.colorPalette ||
        parameters.algorithmSpecificParams != newParameters.algorithmSpecificParams;
    
    parameters.copyWith(
      canvasSize: newParameters.canvasSize,
      colorPalette: newParameters.colorPalette,
      interactionEnabled: newParameters.interactionEnabled,
      algorithmSpecificParams: newParameters.algorithmSpecificParams,
    );
    
    if (needsRegeneration) {
      _initializeFromParameters();
      _generateFractalImage();
    }
  }

  @override
  void dispose() {
    _cachedImage = null;
  }
}