import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:vector_math/vector_math_64.dart';
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';

class VoronoiPoint {
  Vector2 position;
  Vector2 velocity;
  final Color color;

  VoronoiPoint(this.position, this.velocity, this.color);
}

class VoronoiAlgorithm extends GenerativeAlgorithm {
  final List<VoronoiPoint> _points = [];
  final Random _random = Random();
  Offset? _interactionPoint;
  
  VoronoiAlgorithm(ParameterSet parameters) : super(parameters) {
    _initialize();
  }

  void _initialize() {
    _points.clear();
    final pointCount = parameters.algorithmSpecificParams['pointCount'] as int? ?? 20;
    
    final width = parameters.canvasSize.width;
    final height = parameters.canvasSize.height;
    
    for (int i = 0; i < pointCount; i++) {
      _points.add(VoronoiPoint(
        Vector2(
          _random.nextDouble() * width,
          _random.nextDouble() * height,
        ),
        Vector2(
          (_random.nextDouble() - 0.5) * 2,
          (_random.nextDouble() - 0.5) * 2,
        ),
        parameters.colorPalette.getRandomColor(),
      ));
    }
  }

  @override
  void update(Duration delta) {
    if (!parameters.animate) return;
    
    final dt = delta.inMilliseconds / 1000.0;
    _updatePoints(dt);
    _handleInteraction();
  }

  void _updatePoints(double dt) {
    for (final point in _points) {
      point.position += point.velocity * dt * 50;
      
      // Bounce off boundaries
      final width = parameters.canvasSize.width;
      final height = parameters.canvasSize.height;
      
      if (point.position.x < 0) {
        point.position.x = 0;
        point.velocity.x *= -1;
      }
      if (point.position.x > width) {
        point.position.x = width;
        point.velocity.x *= -1;
      }
      if (point.position.y < 0) {
        point.position.y = 0;
        point.velocity.y *= -1;
      }
      if (point.position.y > height) {
        point.position.y = height;
        point.velocity.y *= -1;
      }
    }
  }

  void _handleInteraction() {
    if (!parameters.interactionEnabled || _interactionPoint == null) return;
    
    final interactionPos = Vector2(_interactionPoint!.dx, _interactionPoint!.dy);
    final radius = parameters.interactionRadius;
    final strength = parameters.interactionStrength * 0.1;
    
    for (final point in _points) {
      final direction = point.position - interactionPos;
      final distance = direction.length;
      
      if (distance < radius && distance > 0) {
        direction.normalize();
        direction.scale(strength * (1 - distance / radius));
        point.velocity += direction;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final width = parameters.canvasSize.width.toInt();
    final height = parameters.canvasSize.height.toInt();
    
    canvas.drawRect(
      Offset.zero & parameters.canvasSize,
      Paint()..color = parameters.backgroundColor,
    );

    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 8.0;
    final mode = parameters.algorithmSpecificParams['mode'] as String? ?? 'default';
    
    // Draw Voronoi cells
    for (int y = 0; y < height; y += cellSize.toInt()) {
      for (int x = 0; x < width; x += cellSize.toInt()) {
        final pos = Vector2(x.toDouble(), y.toDouble());
        final (index, dist) = _findClosestPoint(pos);
        
        if (index >= 0) {
          final point = _points[index];
          Color color;
          
          switch (mode) {
            case 'distance':
              final progress = (dist / (width / 2)).clamp(0.0, 1.0);
              color = parameters.colorPalette.getColorAtProgress(1.0 - progress);
              break;
            case 'angle':
              final angle = atan2(
                pos.y - point.position.y,
                pos.x - point.position.x,
              );
              final progress = ((angle + pi) / (2 * pi));
              color = parameters.colorPalette.getColorAtProgress(progress);
              break;
            default:
              color = point.color;
          }
          
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), cellSize, cellSize),
            Paint()..color = color,
          );
        }
      }
    }

    // Draw borders if enabled
    if (parameters.algorithmSpecificParams['showBorders'] == true) {
      for (int y = 0; y < height; y += cellSize.toInt()) {
        for (int x = 0; x < width; x += cellSize.toInt()) {
          final pos = Vector2(x.toDouble(), y.toDouble());
          final (currentIndex, _) = _findClosestPoint(pos);
          
          if (_isBorderCell(x, y, cellSize.toInt(), currentIndex)) {
            canvas.drawRect(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), cellSize, cellSize),
              Paint()
                ..color = material.Colors.white.withOpacity(0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            );
          }
        }
      }
    }

    // Draw points
    if (parameters.algorithmSpecificParams['showPoints'] == true) {
      for (final point in _points) {
        canvas.drawCircle(
          Offset(point.position.x, point.position.y),
          5,
          Paint()..color = point.color,
        );
      }
    }

    // Draw interaction area
    if (parameters.interactionEnabled && _interactionPoint != null) {
      canvas.drawCircle(
        _interactionPoint!,
        parameters.interactionRadius,
        Paint()
          ..color = material.Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  (int, double) _findClosestPoint(Vector2 pos) {
    var minDist = double.infinity;
    var index = -1;
    
    for (int i = 0; i < _points.length; i++) {
      final dist = (pos - _points[i].position).length;
      if (dist < minDist) {
        minDist = dist;
        index = i;
      }
    }
    
    return (index, minDist);
  }

  bool _isBorderCell(int x, int y, int cellSize, int currentIndex) {
    final neighbors = [
      Vector2(x - cellSize.toDouble(), y.toDouble()),
      Vector2(x + cellSize.toDouble(), y.toDouble()),
      Vector2(x.toDouble(), y - cellSize.toDouble()),
      Vector2(x.toDouble(), y + cellSize.toDouble()),
    ];
    
    for (final neighbor in neighbors) {
      if (neighbor.x >= 0 && neighbor.x < parameters.canvasSize.width &&
          neighbor.y >= 0 && neighbor.y < parameters.canvasSize.height) {
        final (neighborIndex, _) = _findClosestPoint(neighbor);
        if (neighborIndex != currentIndex) return true;
      }
    }
    
    return false;
  }

  @override
  void handleInput(Offset position, bool isActive) {
    _interactionPoint = isActive ? position : null;
  }

  @override
  void reset() {
    _initialize();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    final needsReset = 
      parameters.canvasSize != newParameters.canvasSize ||
      parameters.algorithmSpecificParams['pointCount'] != 
      newParameters.algorithmSpecificParams['pointCount'];

    if (needsReset) {
      _initialize();
    }
  }
}