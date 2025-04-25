import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Colors;
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';

enum FractalType {
  mandelbrot,
  julia,
  burningShip,
  tricorn,
  multibrot,
}

class Complex {
  final double re;
  final double im;

  const Complex(this.re, this.im);

  Complex operator +(Complex other) => Complex(re + other.re, im + other.im);
  Complex operator -(Complex other) => Complex(re - other.re, im - other.im);
  Complex operator *(Complex other) => Complex(
    re * other.re - im * other.im,
    re * other.im + im * other.re,
  );

  double abs() => sqrt(re * re + im * im);
  double magnitudeSquared() => re * re + im * im;
}

class FractalAlgorithm extends GenerativeAlgorithm {
  late FractalType _fractalType;
  late Complex _juliaC;
  ui.Image? _cachedImage;
  double _zoom = 1.0;
  Offset _center = Offset.zero;
  bool _isDirty = true;

  FractalAlgorithm(ParameterSet parameters) : super(parameters) {
    _initialize();
  }

  void _initialize() {
    final typeIndex = parameters.algorithmSpecificParams['fractalType'] as int? ?? 0;
    _fractalType = FractalType.values[typeIndex.clamp(0, FractalType.values.length - 1)];
    _juliaC = Complex(
      parameters.algorithmSpecificParams['juliaReal'] as double? ?? -0.4,
      parameters.algorithmSpecificParams['juliaImag'] as double? ?? 0.6,
    );
    _zoom = parameters.algorithmSpecificParams['zoom'] as double? ?? 1.0;
    _isDirty = true;
  }

  @override
  void update(Duration delta) {
    if (!parameters.animate) return;
    
    // Animate julia set parameters
    final t = delta.inMilliseconds / 1000.0;
    _juliaC = Complex(
      0.7885 * cos(t),
      0.7885 * sin(t),
    );
    _isDirty = true;
  }

  @override
  void render(Canvas canvas) {
    if (_isDirty || _cachedImage == null) {
      _generateFractal();
    }
    
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }

  @override
  void handleInput(Offset position, bool isActive) {
    if (!isActive) return;
    
    _center = position;
    _isDirty = true;
  }

  @override
  void reset() {
    _zoom = 1.0;
    _center = Offset.zero;
    _isDirty = true;
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    _initialize();
  }

  void _generateFractal() async {
    final width = parameters.canvasSize.width.toInt();
    final height = parameters.canvasSize.height.toInt();
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Offset.zero & parameters.canvasSize,
      Paint()..color = parameters.backgroundColor,
    );

    // Map screen coordinates to complex plane
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final re = (x - width / 2) * 4 / (width * _zoom) + _center.dx;
        final im = (y - height / 2) * 4 / (height * _zoom) + _center.dy;
        
        final iterations = _calculateFractal(Complex(re, im));
        final color = _getColor(iterations);
        
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          Paint()..color = color,
        );
      }
    }

    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage(width, height);
    _isDirty = false;
  }

  int _calculateFractal(Complex c) {
    const maxIterations = 100;
    Complex z = Complex(0, 0);
    Complex c2 = _fractalType == FractalType.julia ? _juliaC : c;
    
    for (int i = 0; i < maxIterations; i++) {
      if (z.magnitudeSquared() > 4) return i;
      
      switch (_fractalType) {
        case FractalType.mandelbrot:
        case FractalType.julia:
          z = z * z + c2;
          break;
        case FractalType.burningShip:
          z = Complex(z.re.abs(), z.im.abs()) * Complex(z.re.abs(), z.im.abs()) + c2;
          break;
        case FractalType.tricorn:
          z = Complex(z.re, -z.im) * Complex(z.re, -z.im) + c2;
          break;
        case FractalType.multibrot:
          // Higher power creates more complex patterns
          z = z * z * z + c2;
          break;
      }
    }
    
    return maxIterations;
  }

  Color _getColor(int iterations) {
    if (iterations >= 100) return Colors.black;
    
    final progress = iterations / 100.0;
    return parameters.colorPalette.getColorAtProgress(progress);
  }
}