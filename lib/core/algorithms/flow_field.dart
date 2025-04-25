import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/parameter_set.dart';
import '../models/particle.dart';
import '../models/color_palette.dart';

/// Implementation of a flow field algorithm for generative art
class FlowFieldAlgorithm {
  /// List of active particles
  final List<Particle> particles = [];
  
  /// The flow field grid (stores directions)
  late List<List<Vector2>> flowField;
  
  /// Random number generator
  final Random random = Random();
  
  /// Current parameters
  ParameterSet params;
  
  /// Resolution of the flow field grid (lower means smoother)
  int resolution = 20;
  
  /// Noise offset for field generation
  double noiseOffsetX = 0.0;
  double noiseOffsetY = 0.0;
  double noiseOffsetZ = 0.0;
  
  /// Field update interval (frames)
  int fieldUpdateInterval = 30;
  
  /// Current frame count
  int frameCount = 0;
  
  /// User interaction point
  Offset? interactionPoint;
  
  /// Creates a new flow field with the given parameters
  FlowFieldAlgorithm(this.params) {
    // Initialize algorithm specific parameters
    _initAlgorithmParams();
    
    // Create the flow field
    _createFlowField();
    
    // Initialize particles
    _initializeParticles();
  }
  
  /// Initialize algorithm specific parameters from params
  void _initAlgorithmParams() {
    // Get algorithm specific params or use defaults
    final specificParams = params.algorithmSpecificParams;
    resolution = specificParams['resolution'] as int? ?? 20;
    noiseOffsetX = specificParams['noiseOffsetX'] as double? ?? random.nextDouble() * 1000;
    noiseOffsetY = specificParams['noiseOffsetY'] as double? ?? random.nextDouble() * 1000;
    noiseOffsetZ = specificParams['noiseOffsetZ'] as double? ?? random.nextDouble() * 1000;
    fieldUpdateInterval = specificParams['fieldUpdateInterval'] as int? ?? 30;
  }
  
  /// Create the flow field grid
  void _createFlowField() {
    final width = params.canvasSize.width.toInt();
    final height = params.canvasSize.height.toInt();
    
    // Calculate grid dimensions
    final cols = (width / resolution).ceil();
    final rows = (height / resolution).ceil();
    
    // Initialize flow field grid
    flowField = List.generate(
      cols,
      (i) => List.generate(
        rows,
        (j) => _calculateFlowVector(i, j),
      ),
    );
  }
  
  /// Calculate flow vector at grid position using noise
  Vector2 _calculateFlowVector(int col, int row) {
    // Convert grid position to pixel coordinates
    final x = col * resolution;
    final y = row * resolution;
    
    // Calculate noise value (simplex noise approximation)
    final angle = _noise(
      (x * 0.01) + noiseOffsetX,
      (y * 0.01) + noiseOffsetY,
      noiseOffsetZ
    ) * pi * 4;
    
    // Convert angle to vector direction
    return Vector2(cos(angle), sin(angle));
  }
  
  /// Simple noise function (approximation of simplex noise)
  double _noise(double x, double y, double z) {
    // Simple noise function that uses sin/cos
    // Note: In a production app, we'd use a proper noise implementation
    return (sin(x) * cos(y) * sin(z) + 
            cos(x * 1.3) * sin(y * 0.7) * cos(z * 1.5) + 
            sin(x * 2.3) * sin(y * 1.9) * cos(z * 0.8)) / 3 + 0.5;
  }
  
  /// Initialize particles based on current parameters
  void _initializeParticles() {
    particles.clear();
    
    for (int i = 0; i < params.particleCount; i++) {
      particles.add(_createParticle());
    }
  }
  
  /// Create a single particle with appropriate properties
  Particle _createParticle() {
    final position = _getRandomPosition();
    final velocity = Vector2(0, 0); // Velocity will be determined by flow field
    final size = _getRandomSize();
    final color = _getParticleColor(position);
    
    return Particle(
      position: position,
      velocity: velocity,
      acceleration: Vector2(0, 0),
      size: size,
      color: color,
      shape: params.particleShape,
      decay: _getRandomDecay(),
    );
  }
  
  /// Get a random position within the canvas
  Vector2 _getRandomPosition() {
    return Vector2(
      random.nextDouble() * params.canvasSize.width,
      random.nextDouble() * params.canvasSize.height,
    );
  }
  
  /// Get a random size within the particle size range
  double _getRandomSize() {
    return params.minParticleSize +
        random.nextDouble() * (params.maxParticleSize - params.minParticleSize);
  }
  
  /// Get random decay rate
  double _getRandomDecay() {
    // Slower decay for flow field to create longer trails
    return 0.001 + random.nextDouble() * 0.005;
  }
  
  /// Determine particle color based on position and color palette
  Color _getParticleColor(Vector2 position) {
    final colorPalette = params.colorPalette;
    
    switch (colorPalette.colorMode) {
      case ColorMode.position:
        // Color based on 2D position
        final progressX = position.x / params.canvasSize.width;
        final progressY = position.y / params.canvasSize.height;
        final progress = (progressX + progressY) / 2;
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.gradient:
        // Gradient based on vertical position
        final progress = position.y / params.canvasSize.height;
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.random:
        return colorPalette.getRandomColor();
        
      default:
        // Other color modes
        if (colorPalette.colors.isEmpty) {
          return Colors.white.withOpacity(colorPalette.opacity);
        }
        return colorPalette.colors.first.withOpacity(colorPalette.opacity);
    }
  }
  
  /// Update the simulation
  void update() {
    frameCount++;
    
    // Update flow field periodically
    if (frameCount % fieldUpdateInterval == 0) {
      _updateFlowField();
    }
    
    // Update each particle based on flow field
    for (int i = particles.length - 1; i >= 0; i--) {
      // Get flow direction for this particle
      final flowForce = _getFlowForce(particles[i].position);
      
      // Apply flow force
      particles[i].applyForce(flowForce);
      
      // Apply user interaction force if enabled
      if (params.interactionEnabled && interactionPoint != null) {
        _applyInteractionForce(particles[i]);
      }
      
      // Update particle
      particles[i].update(params);
      
      // Update color for specific color modes
      _updateParticleColor(particles[i]);
      
      // If particle is dead or out of bounds, replace it
      if (!particles[i].isAlive() || _isOutOfBounds(particles[i].position)) {
        particles[i] = _createParticle();
      }
    }
  }
  
  /// Gradually update the flow field
  void _updateFlowField() {
    // Animate noise offsets to make the flow field change over time
    noiseOffsetZ += 0.01;
    
    // Update random cells for efficiency rather than the entire grid
    final cols = flowField.length;
    final rows = flowField[0].length;
    
    // Update ~10% of cells per frame
    final cellsToUpdate = (cols * rows * 0.1).round();
    
    for (int i = 0; i < cellsToUpdate; i++) {
      final col = random.nextInt(cols);
      final row = random.nextInt(rows);
      flowField[col][row] = _calculateFlowVector(col, row);
    }
  }
  
  /// Get the flow force at a specific position
  Vector2 _getFlowForce(Vector2 position) {
    // Convert position to grid coordinates
    final col = (position.x / resolution).floor();
    final row = (position.y / resolution).floor();
    
    // Ensure coords are within bounds
    final cols = flowField.length;
    final rows = flowField[0].length;
    
    if (col < 0 || col >= cols || row < 0 || row >= rows) {
      return Vector2(0, 0);
    }
    
    // Get flow direction at this position
    final flowVector = flowField[col][row];
    
    // Scale based on speed parameter
    return flowVector.scaled(params.speed * 0.05);
  }
  
  /// Apply forces based on user interaction point
  void _applyInteractionForce(Particle particle) {
    if (interactionPoint == null) return;
    
    final interactionVector = Vector2(interactionPoint!.dx, interactionPoint!.dy);
    final direction = interactionVector - particle.position;
    final distance = direction.length;
    
    if (distance < params.interactionRadius && distance > 0) {
      // Force diminishes with distance
      final forceFactor = 1.0 - (distance / params.interactionRadius);
      direction.normalize();
      direction.scale(forceFactor * params.interactionStrength * 0.02);
      
      particle.applyForce(direction);
    }
  }
  
  /// Update particle color for specific color modes
  void _updateParticleColor(Particle particle) {
    final colorPalette = params.colorPalette;
    
    if (colorPalette.colorMode == ColorMode.velocity) {
      // Color based on velocity
      final speed = particle.velocity.length;
      final maxSpeed = 2.0;
      final progress = min(1.0, speed / maxSpeed);
      particle.color = colorPalette.getColorAtProgress(progress);
    } 
    else if (colorPalette.colorMode == ColorMode.age) {
      // Color based on age
      final progress = particle.getAgeProgress();
      particle.color = colorPalette.getColorAtProgress(progress);
    }
  }
  
  /// Check if a position is outside the canvas bounds
  bool _isOutOfBounds(Vector2 position) {
    final margin = 10.0;
    return position.x < -margin ||
           position.y < -margin ||
           position.x > params.canvasSize.width + margin ||
           position.y > params.canvasSize.height + margin;
  }
  
  /// Update parameter settings
  void updateParameters(ParameterSet newParams) {
    final bool needsReinit = 
        newParams.algorithmType != params.algorithmType ||
        newParams.particleCount != params.particleCount ||
        newParams.particleShape != params.particleShape;
        
    // Update resolution if it changed in algorithm specific params
    final newResolution = newParams.algorithmSpecificParams['resolution'] as int? ?? resolution;
    final bool fieldNeedsUpdate = newResolution != resolution;
    
    // Store new parameters
    params = newParams;
    
    // Re-initialize algorithm specific parameters
    _initAlgorithmParams();
    
    // Recreation of flow field if needed
    if (fieldNeedsUpdate) {
      _createFlowField();
    }
    
    // Re-initialize particles if needed
    if (needsReinit) {
      _initializeParticles();
    }
  }
  
  /// Set the interaction point
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  /// Render particles to the canvas
  void render(Canvas canvas) {
    // First render flow field if debug mode is on
    if (params.algorithmSpecificParams['showFlowField'] == true) {
      _renderFlowField(canvas);
    }
    
    // Render all particles
    for (var particle in particles) {
      particle.render(canvas, params);
    }
  }
  
  /// Render the flow field (for debugging/visualization)
  void _renderFlowField(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < flowField.length; i++) {
      for (int j = 0; j < flowField[i].length; j++) {
        final x = i * resolution.toDouble();
        final y = j * resolution.toDouble();
        
        // Get flow direction
        final direction = flowField[i][j];
        
        // Draw a small line showing the direction
        canvas.drawLine(
          Offset(x, y),
          Offset(x + direction.x * 10, y + direction.y * 10),
          paint,
        );
      }
    }
  }
}