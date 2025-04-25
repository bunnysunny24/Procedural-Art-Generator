import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'generative_algorithm.dart';
import '../models/parameter_set.dart';

/// Implementation of a Voronoi diagram algorithm
class VoronoiAlgorithm extends GenerativeAlgorithm {
  /// List of points that define the Voronoi cells
  late List<Vector2> _points;
  
  /// Cached image of the Voronoi diagram
  ui.Image? _cachedImage;
  
  /// Whether the diagram needs to be regenerated
  bool _needsRegeneration = true;
  
  /// Random number generator
  final Random _random = Random();
  
  VoronoiAlgorithm(super.parameters) {
    _initialize();
  }
  
  void _initialize() {
    // Generate points for Voronoi cells
    _generatePoints();
    
    // Mark for regeneration
    _needsRegeneration = true;
    _cachedImage = null;
  }
  
  void _generatePoints() {
    _points = [];
    
    // Get number of points from parameters or use default
    final pointCount = parameters.algorithmSpecificParams['pointCount'] as int? ?? 20;
    final canvasWidth = parameters.canvasSize.width;
    final canvasHeight = parameters.canvasSize.height;
    
    // Generate random points
    for (int i = 0; i < pointCount; i++) {
      _points.add(Vector2(
        _random.nextDouble() * canvasWidth,
        _random.nextDouble() * canvasHeight,
      ));
    }
  }
  
  @override
  void update() {
    // Move points if animation is enabled
    if (parameters.animate) {
      _animatePoints();
    }
    
    // Handle interaction
    if (parameters.interactionEnabled && interactionPoint != null) {
      _handleInteraction();
    }
  }
  
  void _animatePoints() {
    final speed = parameters.speed * 0.5;
    final canvasWidth = parameters.canvasSize.width;
    final canvasHeight = parameters.canvasSize.height;
    
    for (int i = 0; i < _points.length; i++) {
      // Apply simple random movement
      _points[i].x += (_random.nextDouble() * 2 - 1) * speed;
      _points[i].y += (_random.nextDouble() * 2 - 1) * speed;
      
      // Keep points within canvas bounds
      _points[i].x = _points[i].x.clamp(0, canvasWidth);
      _points[i].y = _points[i].y.clamp(0, canvasHeight);
    }
    
    // Mark for regeneration
    _needsRegeneration = true;
  }
  
  void _handleInteraction() {
    if (interactionPoint == null) return;
    
    final interactionVector = Vector2(interactionPoint!.dx, interactionPoint!.dy);
    final interactionRadius = parameters.interactionRadius;
    final interactionStrength = parameters.interactionStrength * 0.1;
    
    // Push nearby points away from the interaction point
    for (int i = 0; i < _points.length; i++) {
      final direction = _points[i] - interactionVector;
      final distance = direction.length;
      
      if (distance < interactionRadius && distance > 0) {
        // Calculate push force
        direction.normalize();
        final force = (1.0 - distance / interactionRadius) * interactionStrength;
        direction.scale(force);
        
        // Apply force to point
        _points[i] += direction;
      }
    }
    
    // Mark for regeneration
    _needsRegeneration = true;
  }
  
  @override
  void render(Canvas canvas) {
    final width = parameters.canvasSize.width.toInt();
    final height = parameters.canvasSize.height.toInt();
    
    // Generate or use cached image
    if (_needsRegeneration || _cachedImage == null) {
      _generateVoronoiImage(width, height);
      _needsRegeneration = false;
    }
    
    // Draw the cached image
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
    
    // Draw cell points if enabled
    if (parameters.algorithmSpecificParams['showPoints'] == true) {
      _drawPoints(canvas);
    }
    
    // Draw interaction indicator
    if (parameters.interactionEnabled && interactionPoint != null) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      canvas.drawCircle(interactionPoint!, parameters.interactionRadius, paint);
    }
  }
  
  Future<void> _generateVoronoiImage(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Determine Voronoi mode
    final mode = parameters.algorithmSpecificParams['mode'] as String? ?? 'default';
    final useGradients = parameters.algorithmSpecificParams['useGradients'] == true;
    
    // Draw Voronoi cells using nearest point method
    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 8.0;
    final stepSize = cellSize.toInt();
    
    // Use step size for efficiency - not calculating every pixel
    for (int y = 0; y < height; y += stepSize) {
      for (int x = 0; x < width; x += stepSize) {
        final point = Vector2(x.toDouble(), y.toDouble());
        int nearestIndex = _findNearestPointIndex(point);
        
        // Determine color based on mode
        Color color;
        
        switch (mode) {
          case 'distance':
            // Color based on distance to nearest point
            final distance = (point - _points[nearestIndex]).length;
            final maxDist = sqrt(width * width + height * height);
            final progress = distance / maxDist;
            color = parameters.colorPalette.getColorAtProgress(progress);
            break;
            
          case 'index':
            // Color based on index of nearest point
            final progress = nearestIndex / _points.length;
            color = parameters.colorPalette.getColorAtProgress(progress);
            break;
            
          case 'position':
            // Color based on position of point
            final progress = (_points[nearestIndex].x / width + _points[nearestIndex].y / height) / 2;
            color = parameters.colorPalette.getColorAtProgress(progress);
            break;
            
          case 'default':
          default:
            // Use index-based coloring
            final progress = nearestIndex / _points.length;
            color = parameters.colorPalette.getColorAtProgress(progress);
            break;
        }
        
        // Draw cell rectangle
        final rect = Rect.fromLTWH(x.toDouble(), y.toDouble(), stepSize.toDouble(), stepSize.toDouble());
        canvas.drawRect(rect, Paint()..color = color);
      }
    }
    
    // Draw borders if enabled
    if (parameters.algorithmSpecificParams['showBorders'] == true) {
      _drawVoronoiBorders(canvas, width, height);
    }
    
    // Create image from canvas
    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage(width, height);
  }
  
  int _findNearestPointIndex(Vector2 target) {
    // Find index of nearest point to target
    int nearest = 0;
    double minDist = double.infinity;
    
    for (int i = 0; i < _points.length; i++) {
      final dist = (target - _points[i]).length2;
      
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }
    
    return nearest;
  }
  
  void _drawVoronoiBorders(Canvas canvas, int width, int height) {
    // This is a simplified border detection algorithm
    // A more accurate one would use Fortune's algorithm or similar
    
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final stepSize = 4; // Smaller step size for better border detection
    
    for (int y = 0; y < height; y += stepSize) {
      for (int x = 0; x < width; x += stepSize) {
        final point = Vector2(x.toDouble(), y.toDouble());
        final currentIndex = _findNearestPointIndex(point);
        
        // Check neighboring pixels
        bool isBorder = false;
        
        // Check right neighbor
        if (x + stepSize < width) {
          final rightPoint = Vector2((x + stepSize).toDouble(), y.toDouble());
          final rightIndex = _findNearestPointIndex(rightPoint);
          
          if (rightIndex != currentIndex) {
            isBorder = true;
          }
        }
        
        // Check bottom neighbor
        if (!isBorder && y + stepSize < height) {
          final bottomPoint = Vector2(x.toDouble(), (y + stepSize).toDouble());
          final bottomIndex = _findNearestPointIndex(bottomPoint);
          
          if (bottomIndex != currentIndex) {
            isBorder = true;
          }
        }
        
        // Draw border pixel
        if (isBorder) {
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), stepSize.toDouble(), stepSize.toDouble()),
            borderPaint,
          );
        }
      }
    }
  }
  
  void _drawPoints(Canvas canvas) {
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    for (final point in _points) {
      canvas.drawCircle(Offset(point.x, point.y), 3, pointPaint);
    }
  }
  
  @override
  void reset() {
    _initialize();
  }
  
  @override
  void updateParameters(ParameterSet newParameters) {
    final oldParams = parameters;
    parameters = newParameters;
    
    // Reinitialize if essential parameters changed
    if (oldParams.canvasSize != newParameters.canvasSize || 
        oldParams.algorithmSpecificParams['pointCount'] != newParameters.algorithmSpecificParams['pointCount']) {
      _initialize();
    } else {
      // Just mark for regeneration
      _needsRegeneration = true;
    }
  }
  
  @override
  void handleInteraction(Offset? point) {
    interactionPoint = point;
    if (point != null) {
      _needsRegeneration = true;
    }
  }
  
  @override
  Future<ui.Image?> createPreview(Size size) async {
    // Implementation will depend on how you plan to use previews
    return null;
  }
}