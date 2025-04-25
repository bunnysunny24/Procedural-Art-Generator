import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'algorithm_factory.dart';
import '../models/parameter_set.dart';
import '../models/particle.dart';

/// Implementation of a particle system algorithm
class ParticleSystemAlgorithm implements GenerativeAlgorithm {
  /// Current parameter set for this algorithm
  final ParameterSet parameters;
  
  /// List of particles in the system
  final List<Particle> _particles = [];
  
  /// Random number generator
  final Random _random = Random();
  
  /// Current interaction point for user interaction
  Offset? _interactionPoint;
  
  /// Constructor
  ParticleSystemAlgorithm(this.parameters) {
    _initializeParticles();
  }
  
  /// Initialize all particles based on current parameters
  void _initializeParticles() {
    _particles.clear();
    
    for (int i = 0; i < parameters.particleCount; i++) {
      _createParticle();
    }
  }
  
  /// Create a single particle with properties based on parameters
  void _createParticle() {
    final position = _getRandomPosition();
    final velocity = _getRandomVelocity();
    final size = _getRandomSize();
    final color = _getParticleColor(position);
    
    _particles.add(
      Particle(
        position: position,
        velocity: velocity,
        acceleration: Vector2(0, 0),
        size: size,
        color: color,
        shape: parameters.particleShape,
        decay: _random.nextDouble() * 0.005 + 0.001,
      ),
    );
  }
  
  /// Get a random position for a new particle
  Vector2 _getRandomPosition() {
    return Vector2(
      _random.nextDouble() * parameters.canvasSize.width,
      _random.nextDouble() * parameters.canvasSize.height,
    );
  }
  
  /// Get a random velocity based on movement behavior
  Vector2 _getRandomVelocity() {
    double maxSpeed = parameters.speed;
    
    switch (parameters.movementBehavior) {
      case MovementBehavior.directed:
        // Velocity in a general direction (mostly right/down)
        return Vector2(
          _random.nextDouble() * maxSpeed * 0.8 + maxSpeed * 0.2,
          _random.nextDouble() * maxSpeed * 0.8 + maxSpeed * 0.2,
        );
        
      case MovementBehavior.follow:
      case MovementBehavior.orbit:
        // Start with very little velocity for these behaviors
        return Vector2(
          (_random.nextDouble() * 0.4 - 0.2) * maxSpeed,
          (_random.nextDouble() * 0.4 - 0.2) * maxSpeed,
        );
        
      case MovementBehavior.random:
      default:
        // Completely random velocity
        return Vector2(
          (_random.nextDouble() * 2 - 1) * maxSpeed,
          (_random.nextDouble() * 2 - 1) * maxSpeed,
        );
    }
  }
  
  /// Get a random size for a new particle
  double _getRandomSize() {
    return parameters.minParticleSize + 
      _random.nextDouble() * (parameters.maxParticleSize - parameters.minParticleSize);
  }
  
  /// Get a color for a particle based on position and color mode
  Color _getParticleColor(Vector2 position) {
    switch (parameters.colorPalette.colorMode) {
      case ColorMode.position:
        // Base color on position in the canvas
        final progress = position.x / parameters.canvasSize.width;
        return parameters.colorPalette.getColorAtProgress(progress);
        
      case ColorMode.random:
        // Get a random color from the palette
        return parameters.colorPalette.getRandomColor();
        
      case ColorMode.single:
        // Use the first color in the palette
        return parameters.colorPalette.colors.first.withOpacity(parameters.colorPalette.opacity);
        
      case ColorMode.gradient:
        // Base color on Y position for vertical gradient
        final progress = position.y / parameters.canvasSize.height;
        return parameters.colorPalette.getColorAtProgress(progress);
        
      case ColorMode.custom:
      case ColorMode.velocity:
      case ColorMode.age:
      default:
        // Default to first color if mode not implemented
        return parameters.colorPalette.colors.first.withOpacity(parameters.colorPalette.opacity);
    }
  }
  
  @override
  void update() {
    // Apply the specific movement behavior
    _applyMovementBehavior();
    
    // Apply interaction forces if enabled
    if (parameters.interactionEnabled && _interactionPoint != null) {
      _applyInteractionForces();
    }
    
    // Update each particle
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(parameters);
      
      // Replace dead particles
      if (!_particles[i].isAlive()) {
        _particles[i] = _createReplacementParticle();
      }
    }
    
    // Handle collisions if enabled
    if (parameters.enableCollisions) {
      _handleCollisions();
    }
  }
  
  /// Apply forces based on the current movement behavior
  void _applyMovementBehavior() {
    switch (parameters.movementBehavior) {
      case MovementBehavior.orbit:
        _applyOrbitBehavior();
        break;
        
      case MovementBehavior.follow:
        _applyFollowBehavior();
        break;
        
      case MovementBehavior.attract:
        _applyAttractionBehavior(true);
        break;
        
      case MovementBehavior.repel:
        _applyAttractionBehavior(false);
        break;
        
      case MovementBehavior.wave:
        _applyWaveBehavior();
        break;
        
      case MovementBehavior.bounce:
      case MovementBehavior.directed:
      case MovementBehavior.random:
      default:
        // These behaviors are handled in particle update or initial velocity
        break;
    }
  }
  
  /// Apply orbit behavior where particles orbit around center
  void _applyOrbitBehavior() {
    final centerX = parameters.canvasSize.width / 2;
    final centerY = parameters.canvasSize.height / 2;
    
    for (var particle in _particles) {
      final dx = particle.position.x - centerX;
      final dy = particle.position.y - centerY;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance > 0) {
        // Apply perpendicular force to create orbital motion
        particle.applyForce(Vector2(
          -dy * 0.0001 * parameters.speed,
          dx * 0.0001 * parameters.speed,
        ));
        
        // Apply slight attractive force to keep particles in orbit
        particle.applyForce(Vector2(
          -dx * 0.00001 * distance,
          -dy * 0.00001 * distance,
        ));
      }
    }
  }
  
  /// Apply follow behavior where particles follow each other
  void _applyFollowBehavior() {
    if (_particles.isEmpty) return;
    
    // Each particle follows the one ahead of it
    for (int i = 0; i < _particles.length; i++) {
      final followIndex = (i + 1) % _particles.length;
      final particle = _particles[i];
      final target = _particles[followIndex];
      
      final dx = target.position.x - particle.position.x;
      final dy = target.position.y - particle.position.y;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance > 0) {
        // Apply force toward target
        particle.applyForce(Vector2(
          dx * 0.001 * parameters.speed,
          dy * 0.001 * parameters.speed,
        ));
      }
    }
  }
  
  /// Apply attraction or repulsion behavior
  void _applyAttractionBehavior(bool attract) {
    final centerX = parameters.canvasSize.width / 2;
    final centerY = parameters.canvasSize.height / 2;
    final direction = attract ? -1.0 : 1.0;
    
    for (var particle in _particles) {
      final dx = particle.position.x - centerX;
      final dy = particle.position.y - centerY;
      final distanceSquared = dx * dx + dy * dy;
      
      if (distanceSquared > 1) {
        // Force inversely proportional to distance squared
        final force = direction * 10 / distanceSquared;
        
        particle.applyForce(Vector2(
          dx * force * parameters.speed,
          dy * force * parameters.speed,
        ));
      }
    }
  }
  
  /// Apply wave-like motion
  void _applyWaveBehavior() {
    final time = DateTime.now().millisecondsSinceEpoch * 0.001;
    
    for (var particle in _particles) {
      final waveX = sin(particle.position.x * 0.01 + time) * 0.03;
      final waveY = cos(particle.position.y * 0.01 + time) * 0.03;
      
      particle.applyForce(Vector2(
        waveX * parameters.speed,
        waveY * parameters.speed,
      ));
    }
  }
  
  /// Apply forces from user interaction
  void _applyInteractionForces() {
    if (_interactionPoint == null) return;
    
    final interactionVector = Vector2(_interactionPoint!.dx, _interactionPoint!.dy);
    final radius = parameters.interactionRadius;
    
    for (var particle in _particles) {
      final direction = interactionVector - particle.position;
      final distance = direction.length;
      
      if (distance < radius && distance > 0) {
        // Normalize and scale force based on distance
        direction.normalize();
        final force = 1.0 - (distance / radius);
        direction.scale(force * parameters.interactionStrength * 0.1);
        
        particle.applyForce(direction);
      }
    }
  }
  
  /// Handle collisions between particles
  void _handleCollisions() {
    if (_particles.length < 2) return;
    
    // Simple collision detection (optimization potential: spatial partitioning)
    for (int i = 0; i < _particles.length; i++) {
      final particleA = _particles[i];
      
      // Only check a subset of particles to improve performance
      for (int j = (i + 1) % 5; j < _particles.length; j += 5) {
        final particleB = _particles[j];
        final collisionThreshold = (particleA.size + particleB.size) / 2;
        
        final dx = particleB.position.x - particleA.position.x;
        final dy = particleB.position.y - particleA.position.y;
        final distance = sqrt(dx * dx + dy * dy);
        
        if (distance < collisionThreshold && distance > 0) {
          // Simple collision response
          final nx = dx / distance;
          final ny = dy / distance;
          
          final relativeVelocityX = particleB.velocity.x - particleA.velocity.x;
          final relativeVelocityY = particleB.velocity.y - particleA.velocity.y;
          
          final impulse = (relativeVelocityX * nx + relativeVelocityY * ny) * 
                        parameters.bounceFactor;
          
          // Apply forces in opposite directions
          particleA.applyForce(Vector2(nx * impulse, ny * impulse));
          particleB.applyForce(Vector2(-nx * impulse, -ny * impulse));
        }
      }
    }
  }
  
  /// Create a replacement for a dead particle
  Particle _createReplacementParticle() {
    // Position new particles at the edge of screen based on movement behavior
    final side = _random.nextInt(4);
    Vector2 position;
    
    switch (side) {
      case 0: // Top
        position = Vector2(
          _random.nextDouble() * parameters.canvasSize.width,
          -5,
        );
        break;
      case 1: // Right
        position = Vector2(
          parameters.canvasSize.width + 5,
          _random.nextDouble() * parameters.canvasSize.height,
        );
        break;
      case 2: // Bottom
        position = Vector2(
          _random.nextDouble() * parameters.canvasSize.width,
          parameters.canvasSize.height + 5,
        );
        break;
      case 3: // Left
      default:
        position = Vector2(
          -5,
          _random.nextDouble() * parameters.canvasSize.height,
        );
        break;
    }
    
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
    );
  }
  
  @override
  void render(Canvas canvas) {
    // Draw particles
    for (final particle in _particles) {
      particle.render(canvas, parameters);
    }
    
    // Optionally draw interaction indicator
    if (parameters.interactionEnabled && _interactionPoint != null) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      canvas.drawCircle(_interactionPoint!, parameters.interactionRadius, paint);
    }
  }
  
  @override
  void updateParameters(ParameterSet params) {
    // Check if we need to reinitialize particles
    if (params.particleCount != parameters.particleCount ||
        params.particleShape != parameters.particleShape ||
        params.algorithmType != parameters.algorithmType) {
      // Update parameters and reinit
      parameters = params;
      _initializeParticles();
    } else {
      // Just update parameters
      parameters = params;
    }
  }
  
  @override
  void handleInteraction(Offset? point) {
    _interactionPoint = point;
  }
}