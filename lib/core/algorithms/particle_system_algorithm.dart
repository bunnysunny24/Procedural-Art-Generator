import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/parameter_set.dart';
import '../models/particle.dart';
import '../models/color_palette.dart';
import 'generative_algorithm.dart';

/// Implementation of particle system generative algorithm
class ParticleSystemAlgorithm extends GenerativeAlgorithm {
  /// List of all particles in the system
  final List<Particle> _particles = [];
  
  /// Random number generator
  final Random _random = Random();
  
  /// Current interaction point
  Offset? _interactionPoint;
  
  /// Whether interaction is currently active
  bool _interactionActive = false;
  
  ParticleSystemAlgorithm(super.parameters) {
    initialize();
  }

  @override
  void initialize() {
    _particles.clear();
    _createParticles();
  }
  
  @override
  void update() {
    _updateParticles();
    
    if (_interactionActive && _interactionPoint != null && parameters.interactionEnabled) {
      _applyInteractionForces();
    }
    
    if (parameters.enableCollisions) {
      _handleCollisions();
    }
  }
  
  @override
  void render(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = parameters.backgroundColor,
    );
    
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
    // Check if particle count or shape changed - requires recreating particles
    final needsRecreate = 
        parameters.particleCount != newParameters.particleCount ||
        parameters.particleShape != newParameters.particleShape;
    
    // Update the parameters
    parameters.copyWith(
      particleCount: newParameters.particleCount,
      particleShape: newParameters.particleShape,
      particleBlending: newParameters.particleBlending,
      minParticleSize: newParameters.minParticleSize,
      maxParticleSize: newParameters.maxParticleSize,
      speed: newParameters.speed,
      turbulence: newParameters.turbulence,
      friction: newParameters.friction,
      gravity: newParameters.gravity,
      wind: newParameters.wind,
      enableCollisions: newParameters.enableCollisions,
      interactionEnabled: newParameters.interactionEnabled,
      interactionStrength: newParameters.interactionStrength,
      interactionRadius: newParameters.interactionRadius,
      colorPalette: newParameters.colorPalette,
    );
    
    if (needsRecreate) {
      initialize();
    }
  }
  
  @override
  void dispose() {
    _particles.clear();
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
    final velocity = _getRandomVelocity();
    final size = _getRandomSize();
    final color = _getParticleColor(position);
    
    return Particle(
      position: position,
      velocity: velocity,
      acceleration: Vector2(0, 0),
      size: size,
      color: color,
      shape: parameters.particleShape,
      decay: _random.nextDouble() * 0.005 + 0.001,
    );
  }
  
  /// Generate a random position within canvas bounds
  Vector2 _getRandomPosition() {
    return Vector2(
      _random.nextDouble() * parameters.canvasSize.width,
      _random.nextDouble() * parameters.canvasSize.height,
    );
  }
  
  /// Generate a random velocity based on movement behavior
  Vector2 _getRandomVelocity() {
    switch (parameters.movementBehavior) {
      case MovementBehavior.directed:
        // All particles move in roughly the same direction
        final baseAngle = pi / 4; // 45 degrees
        final angle = baseAngle + (_random.nextDouble() - 0.5) * 0.5;
        final speed = 0.5 + _random.nextDouble() * 1.0;
        return Vector2(cos(angle) * speed, sin(angle) * speed);
        
      case MovementBehavior.orbit:
        // Orbital-like motion
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 0.3 + _random.nextDouble() * 0.7;
        return Vector2(cos(angle) * speed, sin(angle) * speed);
        
      case MovementBehavior.wave:
        // Wave-like motion
        return Vector2(
          (_random.nextDouble() * 2 - 1) * 0.3,
          (_random.nextDouble() * 2 - 1) * 0.3,
        );
        
      case MovementBehavior.bounce:
        // Faster movement for bouncing
        return Vector2(
          (_random.nextDouble() * 2 - 1) * 2.0,
          (_random.nextDouble() * 2 - 1) * 2.0,
        );
        
      case MovementBehavior.random:
      default:
        // Random direction with moderate speed
        return Vector2(
          (_random.nextDouble() * 2 - 1) * 1.0,
          (_random.nextDouble() * 2 - 1) * 1.0,
        );
    }
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
        // Use the first color in the palette
        return colorPalette.colors.isNotEmpty 
            ? colorPalette.colors.first.withOpacity(colorPalette.opacity)
            : Colors.white.withOpacity(colorPalette.opacity);
        
      case ColorMode.gradient:
        // Position-based gradient
        final progress = position.y / parameters.canvasSize.height;
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.position:
        // 2D position mapping
        final xProgress = position.x / parameters.canvasSize.width;
        final yProgress = position.y / parameters.canvasSize.height;
        final progress = (xProgress + yProgress) / 2;
        return colorPalette.getColorAtProgress(progress);
        
      case ColorMode.random:
        // Random color from palette
        return colorPalette.getRandomColor();
        
      default:
        // Default to first color
        return colorPalette.colors.isNotEmpty 
            ? colorPalette.colors.first.withOpacity(colorPalette.opacity)
            : Colors.white.withOpacity(colorPalette.opacity);
    }
  }
  
  /// Update all particles
  void _updateParticles() {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(parameters);
      
      // Replace dead particles
      if (!_particles[i].isAlive()) {
        _particles[i] = _createParticle();
      }
    }
  }
  
  /// Apply forces to particles based on interaction point
  void _applyInteractionForces() {
    if (_interactionPoint == null) return;
    
    final interactionVector = Vector2(_interactionPoint!.dx, _interactionPoint!.dy);
    final interactionRadius = parameters.interactionRadius;
    final strength = parameters.interactionStrength;
    
    for (var particle in _particles) {
      final direction = interactionVector - particle.position;
      final distance = direction.length;
      
      if (distance < interactionRadius && distance > 0) {
        // Normalize and scale force based on distance
        direction.normalize();
        final force = 1.0 - (distance / interactionRadius);
        direction.scale(force * strength * 0.05);
        particle.applyForce(direction);
      }
    }
  }
  
  /// Handle collisions between particles
  void _handleCollisions() {
    // For large numbers of particles, use simplified collision detection
    if (_particles.length > 1000) {
      _handleSimplifiedCollisions();
      return;
    }
    
    // Full collision detection
    for (int i = 0; i < _particles.length; i++) {
      final particleA = _particles[i];
      
      for (int j = i + 1; j < _particles.length; j++) {
        final particleB = _particles[j];
        final dx = particleA.position.x - particleB.position.x;
        final dy = particleA.position.y - particleB.position.y;
        final distance = sqrt(dx * dx + dy * dy);
        
        // Collision if distance is less than sum of radii
        final minDistance = (particleA.size + particleB.size) / 2.0;
        if (distance < minDistance && distance > 0) {
          // Simple collision response
          final angle = atan2(dy, dx);
          final overlap = minDistance - distance;
          final responseForce = overlap * 0.01 * parameters.bounceFactor;
          
          final forceX = cos(angle) * responseForce;
          final forceY = sin(angle) * responseForce;
          
          particleA.applyForce(Vector2(forceX, forceY));
          particleB.applyForce(Vector2(-forceX, -forceY));
        }
      }
    }
  }
  
  /// Simplified collision detection for large particle counts
  void _handleSimplifiedCollisions() {
    // Spatial partitioning would be better but for simplicity:
    // Just check a subset of particles against others
    for (int i = 0; i < _particles.length; i += 5) {
      final particleA = _particles[i];
      
      for (int j = i + 1; j < min(i + 20, _particles.length); j++) {
        final particleB = _particles[j];
        final distance = particleA.distanceTo(particleB);
        
        // Collision if distance is less than sum of radii
        final minDistance = (particleA.size + particleB.size) / 2.0;
        if (distance < minDistance && distance > 0) {
          final dx = particleA.position.x - particleB.position.x;
          final dy = particleA.position.y - particleB.position.y;
          final angle = atan2(dy, dx);
          final responseForce = (minDistance - distance) * 0.01 * parameters.bounceFactor;
          
          final forceX = cos(angle) * responseForce;
          final forceY = sin(angle) * responseForce;
          
          particleA.applyForce(Vector2(forceX, forceY));
          particleB.applyForce(Vector2(-forceX, -forceY));
        }
      }
    }
  }
}