import 'dart:math';
import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:flutter/material.dart' as material;

import '../models/parameter_set.dart';
import '../models/particle.dart';
import '../models/color_mode.dart';

/// Implementation of a flow field algorithm for generative art
class FlowFieldAlgorithm {
  /// List of active particles
  final List<Particle> particles = [];
  
  /// The flow field
  late FlowField flowField;
  
  /// Random number generator
  final Random random = Random();
  
  /// Current parameters
  ParameterSet params;
  
  /// Noise offset for field generation
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
    flowField = FlowField(params);
    
    // Initialize particles
    _initializeParticles();
  }
  
  /// Initialize algorithm specific parameters from params
  void _initAlgorithmParams() {
    // Get algorithm specific params or use defaults
    final specificParams = params.algorithmSpecificParams;
    noiseOffsetZ = specificParams['noiseOffsetZ'] as double? ?? random.nextDouble() * 1000;
    fieldUpdateInterval = specificParams['fieldUpdateInterval'] as int? ?? 30;
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
          return material.Colors.white.withOpacity(colorPalette.opacity);
        }
        return colorPalette.colors.first.withOpacity(colorPalette.opacity);
    }
  }
  
  /// Update the simulation
  void update() {
    frameCount++;
    
    // Update flow field periodically
    if (frameCount % fieldUpdateInterval == 0) {
      flowField.updateField(noiseOffsetZ);
      noiseOffsetZ += 0.01;
    }
    
    // Update each particle based on flow field
    for (int i = particles.length - 1; i >= 0; i--) {
      // Get flow direction for this particle
      final flowForce = flowField.getFlowVector(particles[i].position);
      
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
        
    // Store new parameters
    params = newParams;
    
    // Re-initialize algorithm specific parameters
    _initAlgorithmParams();
    
    // Recreation of flow field if needed
    if (flowField.needsReset(newParams)) {
      flowField = FlowField(newParams);
    }
    
    // Re-initialize particles if needed
    if (needsReinit) {
      _initializeParticles();
    }
  }
  
  /// Set the interaction point
  void handleInteraction(Offset? point) {
    interactionPoint = point;
    if (point != null) {
      flowField.addDisturbance(point);
    }
  }
  
  /// Render particles to the canvas
  void render(Canvas canvas) {
    // First render flow field if debug mode is on
    flowField.render(canvas);
    
    // Render all particles
    for (var particle in particles) {
      particle.render(canvas, params);
    }
  }
}

/// Flow field class
class FlowField {
  final ParameterSet params;
  final List<List<Vector2>> _field;
  final int _resolution;
  
  FlowField(this.params)
    : _resolution = params.algorithmSpecificParams['resolution'] as int? ?? 20,
      _field = List.generate(
        (params.canvasSize.height / (params.algorithmSpecificParams['resolution'] as int? ?? 20)).ceil(),
        (_) => List.generate(
          (params.canvasSize.width / (params.algorithmSpecificParams['resolution'] as int? ?? 20)).ceil(),
          (_) => Vector2.zero(),
        ),
      );

  Vector2 getFlowVector(Vector2 position) {
    final x = (position.x / params.canvasSize.width * _field[0].length).floor();
    final y = (position.y / params.canvasSize.height * _field.length).floor();
    
    if (x < 0 || x >= _field[0].length || y < 0 || y >= _field.length) {
      return Vector2.zero();
    }
    
    final flowVector = _field[y][x];
    return flowVector.scaled(params.speed * 0.05);
  }

  void updateField(double noiseZ) {
    for (int y = 0; y < _field.length; y++) {
      for (int x = 0; x < _field[y].length; x++) {
        final angle = _generateNoiseAngle(x, y, noiseZ);
        _field[y][x].setValues(cos(angle), sin(angle));
      }
    }
  }

  double _generateNoiseAngle(int x, int y, double z) {
    final frequency = params.algorithmSpecificParams['noiseFrequency'] as double? ?? 0.01;
    final xCoord = x * frequency;
    final yCoord = y * frequency;
    
    // Simplified noise implementation - replace with proper noise function in production
    final noise = sin(xCoord + z) * cos(yCoord + z);
    return noise * 2 * pi;
  }

  void addDisturbance(Offset center) {
    final centerVec = Vector2(center.dx, center.dy);
    final radius = params.interactionRadius;
    final strength = params.interactionStrength;

    for (int y = 0; y < _field.length; y++) {
      for (int x = 0; x < _field[y].length; x++) {
        final worldX = x * _resolution.toDouble();
        final worldY = y * _resolution.toDouble();
        final pos = Vector2(worldX, worldY);
        
        final toPoint = centerVec - pos;
        final distance = toPoint.length;
        
        if (distance < radius && distance > 0) {
          toPoint.normalize();
          final influence = 1.0 - (distance / radius);
          _field[y][x] = toPoint.scaled(influence * strength);
        }
      }
    }
  }

  bool needsReset(ParameterSet newParams) {
    return newParams.algorithmType != params.algorithmType ||
           params.algorithmSpecificParams['resolution'] !=
           newParams.algorithmSpecificParams['resolution'];
  }

  void update(double dt) {
    // Placeholder implementation for update logic.
  }

  void render(Canvas canvas) {
    if (params.algorithmSpecificParams['showFlowField'] == true) {
      final paint = Paint()
        ..strokeWidth = 1
        ..color = material.Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke;

      for (int y = 0; y < _field.length; y++) {
        for (int x = 0; x < _field[y].length; x++) {
          final worldX = x * _resolution.toDouble();
          final worldY = y * _resolution.toDouble();
          final flow = _field[y][x].normalized() * (_resolution * 0.5);
          
          canvas.drawLine(
            Offset(worldX, worldY),
            Offset(worldX + flow.x, worldY + flow.y),
            paint,
          );
        }
      }
    }
  }
}