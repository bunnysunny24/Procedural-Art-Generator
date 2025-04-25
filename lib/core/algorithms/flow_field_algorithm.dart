import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/parameter_set.dart';
import '../models/particle.dart';
import '../models/color_palette.dart';
import 'generative_algorithm.dart';

/// Implementation of flow field generative algorithm
class FlowFieldAlgorithm extends GenerativeAlgorithm {
  /// List of particles flowing through the field
  final List<Particle> _particles = [];
  
  /// The flow field grid storing direction vectors
  late List<List<Vector2>> _flowField;
  
  /// Grid cell size for the flow field
  late double _cellSize;
  
  /// Number of columns in the flow field grid
  late int _cols;
  
  /// Number of rows in the flow field grid
  late int _rows;
  
  /// Random number generator
  final Random _random = Random();
  
  /// Current interaction point
  Offset? _interactionPoint;
  
  /// Whether interaction is currently active
  bool _interactionActive = false;
  
  /// Noise z-offset for field evolution
  double _zOffset = 0.0;

  FlowFieldAlgorithm(super.parameters) {
    initialize();
  }

  @override
  void initialize() {
    // Calculate grid dimensions
    _cellSize = _getCellSize();
    _cols = (parameters.canvasSize.width / _cellSize).ceil();
    _rows = (parameters.canvasSize.height / _cellSize).ceil();
    
    // Initialize flow field
    _initializeFlowField();
    
    // Create particles
    _particles.clear();
    _createParticles();
    
    // Reset noise offset
    _zOffset = 0.0;
  }
  
  /// Calculate cell size based on canvas dimensions
  double _getCellSize() {
    // Extract from algorithm specific params if available
    if (parameters.algorithmSpecificParams.containsKey('cellSize')) {
      return parameters.algorithmSpecificParams['cellSize'] as double;
    }
    
    // Default: divide the smallest dimension by 20-40 cells
    final smallestDimension = min(
      parameters.canvasSize.width, 
      parameters.canvasSize.height
    );
    return smallestDimension / 30.0;
  }
  
  /// Initialize the flow field with direction vectors
  void _initializeFlowField() {
    _flowField = List.generate(
      _cols, 
      (_) => List.generate(
        _rows, 
        (_) => Vector2(0, 0),
      ),
    );
    
    // Generate the initial field
    _generateFlowField();
  }
  
  /// Generate the flow field using noise
  void _generateFlowField() {
    final noiseScale = _getNoiseScale();
    
    for (int i = 0; i < _cols; i++) {
      for (int j = 0; j < _rows; j++) {
        // Use simplified noise approximation
        final angle = _simpleNoise(
          i * noiseScale, 
          j * noiseScale, 
          _zOffset
        ) * 2 * pi;
        
        // Create a unit vector at that angle
        _flowField[i][j] = Vector2(cos(angle), sin(angle));
      }
    }
  }
  
  /// Get noise scale factor from parameters or defaults
  double _getNoiseScale() {
    if (parameters.algorithmSpecificParams.containsKey('noiseScale')) {
      return parameters.algorithmSpecificParams['noiseScale'] as double;
    }
    return 0.1; // Default scale
  }
  
  /// Simple noise function (simplex noise would be better but this is simpler)
  double _simpleNoise(double x, double y, double z) {
    // Combine several sin waves at different frequencies
    return 0.5 + 
      0.5 * sin(x * 0.3 + z) * 
      cos(y * 0.2 + z * 0.7) * 
      sin((x + y) * 0.1 + z * 0.3);
  }
  
  /// Create initial particles
  void _createParticles() {
    for (int i = 0; i < parameters.particleCount; i++) {
      _particles.add(_createParticle());
    }
  }
  
  /// Create a single particle with randomized properties
  Particle _createParticle() {
    final position = _getRandomPosition();
    final size = _getRandomSize();
    final color = _getParticleColor(position);
    
    // For flow fields, initial velocity is based on the flow field
    final velocity = _getFlowDirectionAt(position);
    
    return Particle(
      position: position,
      velocity: velocity,
      acceleration: Vector2(0, 0),
      size: size,
      color: color,
      shape: parameters.particleShape,
      life: 1.0,
      decay: 0.001 + _random.nextDouble() * 0.004,
    );
  }
  
  /// Generate a random position within canvas bounds
  Vector2 _getRandomPosition() {
    return Vector2(
      _random.nextDouble() * parameters.canvasSize.width,
      _random.nextDouble() * parameters.canvasSize.height,
    );
  }
  
  /// Get the flow direction at a specific position
  Vector2 _getFlowDirectionAt(Vector2 position) {
    // Find grid cell
    int col = (position.x / _cellSize).floor();
    int row = (position.y / _cellSize).floor();
    
    // Constrain to grid bounds
    col = col.clamp(0, _cols - 1);
    row = row.clamp(0, _rows - 1);
    
    // Get flow direction at this cell
    return _flowField[col][row].clone();
  }
  
  /// Generate a random particle size within the min/max range
  double _getRandomSize() {
    return parameters.minParticleSize + 
      _random.nextDouble() * (parameters.maxParticleSize - parameters.minParticleSize);
  }
  
  /// Get particle color based on position and color palette settings
  Color _getParticleColor(Vector2 position) {
    final colorPalette = parameters.colorPalette;
    
    switch (colorPalette.colorMode) {
      case ColorMode.single:
        return colorPalette.colors.isNotEmpty 
            ? colorPalette.colors.first.withOpacity(colorPalette.opacity)
            : Colors.white.withOpacity(colorPalette.opacity);
        
      case ColorMode.gradient:
        final progress = position.y / parameters.canvasSize.height;
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.position:
        // Calculate angle from center as the progress
        final centerX = parameters.canvasSize.width / 2;
        final centerY = parameters.canvasSize.height / 2;
        final angle = atan2(
          position.y - centerY, 
          position.x - centerX
        );
        final progress = (angle + pi) / (2 * pi);
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.velocity:
        // Flow direction mapped to color (will be updated during updates)
        return colorPalette.getColorAtProgress(0.5);
        
      case ColorMode.random:
        return colorPalette.getRandomColor();
        
      default:
        return colorPalette.colors.isNotEmpty 
            ? colorPalette.colors.first.withOpacity(colorPalette.opacity)
            : Colors.white.withOpacity(colorPalette.opacity);
    }
  }
  
  @override
  void update() {
    // Evolve the flow field over time
    _zOffset += 0.003 * parameters.speed;
    
    // Regenerate flow field periodically
    if (_zOffset % 0.2 < 0.01) {
      _generateFlowField();
    }
    
    // Apply interaction forces if active
    if (_interactionActive && _interactionPoint != null && parameters.interactionEnabled) {
      _applyInteractionForces();
    }
    
    // Update all particles
    _updateParticles();
  }
  
  /// Update all particles
  void _updateParticles() {
    for (int i = _particles.length - 1; i >= 0; i--) {
      // Get flow force at particle position
      final flowForce = _getFlowDirectionAt(_particles[i].position);
      
      // Scale by parameters
      flowForce.scale(parameters.speed * 0.3);
      
      // Apply to particle
      _particles[i].applyForce(flowForce);
      
      // Update particle
      _particles[i].update(parameters);
      
      // Update color if using velocity-based coloring
      if (parameters.colorPalette.colorMode == ColorMode.velocity) {
        final velocity = _particles[i].velocity;
        final speed = velocity.length;
        final maxSpeed = 3.0 * parameters.speed;
        final progress = (speed / maxSpeed).clamp(0.0, 1.0);
        _particles[i].color = parameters.colorPalette.getColorAtProgress(progress);
      }
      
      // Replace dead particles
      if (!_particles[i].isAlive()) {
        _particles[i] = _createParticle();
      }
    }
  }
  
  /// Apply interaction forces to the flow field
  void _applyInteractionForces() {
    if (_interactionPoint == null) return;
    
    final strength = parameters.interactionStrength;
    final interactX = _interactionPoint!.dx;
    final interactY = _interactionPoint!.dy;
    final radius = parameters.interactionRadius;
    
    // Find affected grid cells
    final minCol = max(0, ((interactX - radius) / _cellSize).floor());
    final maxCol = min(_cols - 1, ((interactX + radius) / _cellSize).ceil());
    final minRow = max(0, ((interactY - radius) / _cellSize).floor());
    final maxRow = min(_rows - 1, ((interactY + radius) / _cellSize).ceil());
    
    for (int i = minCol; i <= maxCol; i++) {
      for (int j = minRow; j <= maxRow; j++) {
        final cellX = i * _cellSize + _cellSize / 2;
        final cellY = j * _cellSize + _cellSize / 2;
        
        final distance = sqrt(
          pow(cellX - interactX, 2) + pow(cellY - interactY, 2)
        );
        
        if (distance < radius) {
          // Direction from interaction point to cell
          final angle = atan2(cellY - interactY, cellX - interactX);
          
          // Strength decreases with distance
          final factor = 1.0 - (distance / radius);
          
          // Create a force vector in that direction
          final forceX = cos(angle) * factor * strength;
          final forceY = sin(angle) * factor * strength;
          
          // Add to existing flow
          _flowField[i][j].add(Vector2(forceX, forceY));
          _flowField[i][j].normalize();
        }
      }
    }
  }
  
  @override
  void render(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Optionally display the flow field grid for debugging
    if (parameters.algorithmSpecificParams['showFlowField'] == true) {
      _renderFlowField(canvas);
    }
    
    // Draw all particles
    for (final particle in _particles) {
      particle.render(canvas, parameters);
    }
    
    // Draw interaction indicator if active
    if (parameters.interactionEnabled && _interactionPoint != null && _interactionActive) {
      canvas.drawCircle(
        _interactionPoint!,
        parameters.interactionRadius * 0.5,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
  
  /// Render the flow field grid for visualization
  void _renderFlowField(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < _cols; i++) {
      for (int j = 0; j < _rows; j++) {
        final x = i * _cellSize;
        final y = j * _cellSize;
        
        // Draw cell
        canvas.drawRect(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          paint,
        );
        
        // Draw direction vector
        final center = Offset(x + _cellSize / 2, y + _cellSize / 2);
        final direction = _flowField[i][j].normalized() * (_cellSize * 0.4);
        
        canvas.drawLine(
          center,
          Offset(center.dx + direction.x, center.dy + direction.y),
          paint,
        );
      }
    }
  }
  
  @override
  void handleInteraction(Offset? position, bool isPressed) {
    _interactionPoint = position;
    _interactionActive = isPressed;
  }
  
  @override
  void reset() {
    initialize();
  }
  
  @override
  void updateParameters(ParameterSet newParameters) {
    final needsRecreate = 
        parameters.particleCount != newParameters.particleCount ||
        parameters.particleShape != newParameters.particleShape ||
        parameters.canvasSize != newParameters.canvasSize;
    
    parameters.copyWith(
      particleCount: newParameters.particleCount,
      particleShape: newParameters.particleShape,
      canvasSize: newParameters.canvasSize,
      particleBlending: newParameters.particleBlending,
      minParticleSize: newParameters.minParticleSize,
      maxParticleSize: newParameters.maxParticleSize,
      speed: newParameters.speed,
      turbulence: newParameters.turbulence,
      friction: newParameters.friction,
      interactionEnabled: newParameters.interactionEnabled,
      interactionStrength: newParameters.interactionStrength,
      interactionRadius: newParameters.interactionRadius,
      colorPalette: newParameters.colorPalette,
      algorithmSpecificParams: newParameters.algorithmSpecificParams,
    );
    
    if (needsRecreate) {
      initialize();
    }
  }
  
  @override
  void dispose() {
    _particles.clear();
    _flowField.clear();
  }
}