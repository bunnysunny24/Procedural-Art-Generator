import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'generative_algorithm.dart';
import '../models/parameter_set.dart';

/// Implementation of a flow field algorithm
class FlowFieldAlgorithm extends GenerativeAlgorithm {
  /// Grid resolution for the flow field
  late final int _gridResolutionX;
  late final int _gridResolutionY;
  
  /// 2D grid of angle values representing the flow field direction
  late final List<List<double>> _flowField;
  
  /// Particles flowing through the field
  final List<FlowParticle> _particles = [];
  
  /// Random number generator
  final Random _random = Random();
  
  /// Current interaction point
  Offset? interactionPoint;
  
  FlowFieldAlgorithm(super.parameters) {
    _initialize();
  }
  
  void _initialize() {
    // Calculate grid resolution based on canvas size
    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 20.0;
    _gridResolutionX = (parameters.canvasSize.width / cellSize).ceil();
    _gridResolutionY = (parameters.canvasSize.height / cellSize).ceil();
    
    // Generate flow field
    _generateFlowField();
    
    // Create particles
    _initializeParticles();
  }
  
  void _generateFlowField() {
    // Create a 2D flow field of angles
    _flowField = List.generate(
      _gridResolutionX,
      (_) => List.generate(
        _gridResolutionY,
        (_) => 0.0,
      ),
    );
    
    // Apply noise to generate flow field angles
    final noiseScale = parameters.algorithmSpecificParams['noiseScale'] as double? ?? 0.1;
    final seed = DateTime.now().millisecondsSinceEpoch;
    
    for (int x = 0; x < _gridResolutionX; x++) {
      for (int y = 0; y < _gridResolutionY; y++) {
        // Simple Perlin-like noise approximation
        final angle = sin(x * noiseScale + seed * 0.001) * 
                      cos(y * noiseScale + seed * 0.002) * 2 * pi;
        _flowField[x][y] = angle;
      }
    }
  }
  
  void _initializeParticles() {
    _particles.clear();
    
    final count = parameters.particleCount;
    for (int i = 0; i < count; i++) {
      _particles.add(FlowParticle(
        position: Vector2(
          _random.nextDouble() * parameters.canvasSize.width,
          _random.nextDouble() * parameters.canvasSize.height,
        ),
        color: _getParticleColor(i / count),
        size: _getParticleSize(),
      ));
    }
  }
  
  Color _getParticleColor(double progress) {
    return parameters.colorPalette.getColorAtProgress(progress);
  }
  
  double _getParticleSize() {
    return parameters.minParticleSize + 
      _random.nextDouble() * (parameters.maxParticleSize - parameters.minParticleSize);
  }
  
  @override
  void update() {
    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 20.0;
    final speed = parameters.speed;
    
    // Update each particle based on flow field
    for (final particle in _particles) {
      // Calculate grid coordinates
      final gridX = (particle.position.x / cellSize).floor().clamp(0, _gridResolutionX - 1);
      final gridY = (particle.position.y / cellSize).floor().clamp(0, _gridResolutionY - 1);
      
      // Get flow angle at grid position
      final angle = _flowField[gridX][gridY];
      
      // Calculate velocity vector based on flow angle
      final velX = cos(angle) * speed;
      final velY = sin(angle) * speed;
      
      // Update particle position
      particle.position.x += velX;
      particle.position.y += velY;
      
      // Handle edges
      _handleEdges(particle);
      
      // Update trail
      particle.updateTrail();
    }
    
    // Apply interaction if enabled
    if (parameters.interactionEnabled && interactionPoint != null) {
      _applyInteraction(interactionPoint!);
    }
  }
  
  void _handleEdges(FlowParticle particle) {
    final width = parameters.canvasSize.width;
    final height = parameters.canvasSize.height;
    
    // Wrap particles around edges
    if (particle.position.x < 0) particle.position.x = width;
    if (particle.position.x > width) particle.position.x = 0;
    if (particle.position.y < 0) particle.position.y = height;
    if (particle.position.y > height) particle.position.y = 0;
    
    // Clear trail when wrapping
    if (particle.justWrapped) {
      particle.clearTrail();
    }
  }
  
  void _applyInteraction(Offset point) {
    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 20.0;
    final interactionRadius = parameters.interactionRadius ~/ cellSize;
    final interactX = (point.dx / cellSize).floor();
    final interactY = (point.dy / cellSize).floor();
    
    // Modify flow field around interaction point
    for (int x = interactX - interactionRadius; x <= interactX + interactionRadius; x++) {
      for (int y = interactY - interactionRadius; y <= interactY + interactionRadius; y++) {
        if (x >= 0 && y >= 0 && x < _gridResolutionX && y < _gridResolutionY) {
          // Calculate angle pointing towards or away from interaction point
          final dx = x - interactX;
          final dy = y - interactY;
          final dist = sqrt(dx * dx + dy * dy);
          
          if (dist > 0 && dist <= interactionRadius) {
            final angle = atan2(dy, dx);
            final strength = 1 - (dist / interactionRadius);
            
            // Modify existing angle with interaction
            _flowField[x][y] = angle + (pi * strength * parameters.interactionStrength * 0.1);
          }
        }
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, parameters.canvasSize.width, parameters.canvasSize.height),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Draw flow field lines (for debugging)
    if (parameters.algorithmSpecificParams['showFlowField'] == true) {
      _renderFlowField(canvas);
    }
    
    // Draw particles and their trails
    for (final particle in _particles) {
      _renderParticle(canvas, particle);
    }
  }
  
  void _renderFlowField(Canvas canvas) {
    final cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 20.0;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    for (int x = 0; x < _gridResolutionX; x++) {
      for (int y = 0; y < _gridResolutionY; y++) {
        final angle = _flowField[x][y];
        final centerX = x * cellSize + cellSize / 2;
        final centerY = y * cellSize + cellSize / 2;
        
        final lineLength = cellSize * 0.5;
        final endX = centerX + cos(angle) * lineLength;
        final endY = centerY + sin(angle) * lineLength;
        
        canvas.drawLine(
          Offset(centerX, centerY),
          Offset(endX, endY),
          paint,
        );
      }
    }
  }
  
  void _renderParticle(Canvas canvas, FlowParticle particle) {
    // Draw trail
    if (parameters.algorithmSpecificParams['showTrails'] != false && 
        particle.trail.length > 1) {
      final trailPaint = Paint()
        ..color = particle.color.withOpacity(0.5 * parameters.particleOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = particle.size / 2;
        
      final path = Path();
      path.moveTo(particle.trail.first.x, particle.trail.first.y);
      
      for (int i = 1; i < particle.trail.length; i++) {
        path.lineTo(particle.trail[i].x, particle.trail[i].y);
      }
      
      canvas.drawPath(path, trailPaint);
    }
    
    // Draw particle
    final particlePaint = Paint()
      ..color = particle.color.withOpacity(parameters.particleOpacity)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(
      Offset(particle.position.x, particle.position.y),
      particle.size / 2,
      particlePaint,
    );
  }
  
  @override
  void reset() {
    _generateFlowField();
    _initializeParticles();
  }
  
  @override
  void updateParameters(ParameterSet newParameters) {
    final oldParams = parameters;
    parameters = newParameters;
    
    // Regenerate field and particles if essential parameters changed
    if (oldParams.canvasSize != newParameters.canvasSize ||
        oldParams.particleCount != newParameters.particleCount ||
        oldParams.algorithmSpecificParams['cellSize'] != newParameters.algorithmSpecificParams['cellSize']) {
      _initialize();
    }
  }
  
  @override
  Future<ui.Image?> createPreview(Size size) async {
    // Implementation will depend on how you plan to use previews
    return null;
  }
}

/// Particle for the flow field
class FlowParticle {
  /// Current position
  Vector2 position;
  
  /// Color of the particle
  Color color;
  
  /// Size of the particle
  double size;
  
  /// Previous positions for trail rendering
  final List<Vector2> trail = [];
  
  /// Maximum trail length
  final int maxTrailLength;
  
  /// Whether the particle just wrapped around an edge
  bool justWrapped = false;
  
  FlowParticle({
    required this.position,
    required this.color,
    required this.size,
    this.maxTrailLength = 20,
  });
  
  /// Add current position to trail
  void updateTrail() {
    trail.add(Vector2(position.x, position.y));
    if (trail.length > maxTrailLength) {
      trail.removeAt(0);
    }
    justWrapped = false;
  }
  
  /// Clear the trail
  void clearTrail() {
    trail.clear();
    justWrapped = true;
  }
}