import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';

import '../models/parameter_set.dart';
import '../models/particle.dart';
import '../models/color_palette.dart';

/// Implementation of a particle system algorithm for generative art
class ParticleSystemAlgorithm {
  /// List of active particles
  final List<Particle> particles = [];
  
  /// Random number generator
  final Random random = Random();
  
  /// Current parameters
  ParameterSet params;
  
  /// Current interaction point (for user interaction)
  Offset? interactionPoint;
  
  /// Creates a new particle system with the given parameters
  ParticleSystemAlgorithm(this.params) {
    _initializeParticles();
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
    final position = _getInitialPosition();
    final velocity = _getInitialVelocity();
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
  
  /// Determine initial position based on movement behavior
  Vector2 _getInitialPosition() {
    final width = params.canvasSize.width;
    final height = params.canvasSize.height;
    
    switch (params.movementBehavior) {
      case MovementBehavior.orbit:
        // Start in a circular pattern
        final angle = random.nextDouble() * pi * 2;
        final radius = random.nextDouble() * min(width, height) * 0.4;
        final centerX = width / 2;
        final centerY = height / 2;
        return Vector2(
          centerX + cos(angle) * radius,
          centerY + sin(angle) * radius,
        );
        
      case MovementBehavior.directed:
        // Start from one edge
        final side = random.nextInt(4);
        switch (side) {
          case 0: // top
            return Vector2(random.nextDouble() * width, 0);
          case 1: // right
            return Vector2(width, random.nextDouble() * height);
          case 2: // bottom
            return Vector2(random.nextDouble() * width, height);
          case 3: // left
          default:
            return Vector2(0, random.nextDouble() * height);
        }
        
      case MovementBehavior.attract:
      case MovementBehavior.repel:
        // Start near edges
        final distFromEdge = 50.0;
        final x = random.nextDouble() < 0.5
            ? random.nextDouble() * distFromEdge
            : width - random.nextDouble() * distFromEdge;
        final y = random.nextDouble() < 0.5
            ? random.nextDouble() * distFromEdge
            : height - random.nextDouble() * distFromEdge;
        return Vector2(x, y);
        
      case MovementBehavior.wave:
      case MovementBehavior.follow:
      case MovementBehavior.bounce:
      case MovementBehavior.random:
      default:
        // Random position anywhere
        return Vector2(
          random.nextDouble() * width,
          random.nextDouble() * height,
        );
    }
  }
  
  /// Determine initial velocity based on movement behavior
  Vector2 _getInitialVelocity() {
    switch (params.movementBehavior) {
      case MovementBehavior.directed:
        // Velocity toward center
        final centerX = params.canvasSize.width / 2;
        final centerY = params.canvasSize.height / 2;
        final dirX = centerX - random.nextDouble() * params.canvasSize.width;
        final dirY = centerY - random.nextDouble() * params.canvasSize.height;
        final direction = Vector2(dirX, dirY)..normalize();
        return direction * (0.5 + random.nextDouble() * 1.5);
        
      case MovementBehavior.orbit:
        // Tangential velocity for orbit
        final centerX = params.canvasSize.width / 2;
        final centerY = params.canvasSize.height / 2;
        final toCenter = Vector2(centerX, centerY) - Vector2(0, 0);
        final perpendicular = Vector2(-toCenter.y, toCenter.x)..normalize();
        return perpendicular * (0.5 + random.nextDouble() * 1.0);
        
      case MovementBehavior.follow:
        // Low velocity that will be affected by forces
        return Vector2(
          random.nextDouble() * 0.2 - 0.1,
          random.nextDouble() * 0.2 - 0.1,
        );
        
      case MovementBehavior.wave:
        // Horizontal base velocity
        return Vector2(
          (random.nextDouble() - 0.5) * 0.5,
          0,
        );
        
      case MovementBehavior.bounce:
        // Higher random velocity for bouncing
        return Vector2(
          (random.nextDouble() * 2 - 1) * 2,
          (random.nextDouble() * 2 - 1) * 2,
        );
        
      case MovementBehavior.attract:
      case MovementBehavior.repel:
      case MovementBehavior.random:
      default:
        // Random velocity
        return Vector2(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        );
    }
  }
  
  /// Get a random size within the particle size range
  double _getRandomSize() {
    return params.minParticleSize +
        random.nextDouble() * (params.maxParticleSize - params.minParticleSize);
  }
  
  /// Get random decay rate
  double _getRandomDecay() {
    // Base decay rate varies to give particles different lifespans
    return 0.002 + random.nextDouble() * 0.008;
  }
  
  /// Determine particle color based on position and color palette
  Color _getParticleColor(Vector2 position) {
    final colorPalette = params.colorPalette;
    
    switch (colorPalette.colorMode) {
      case ColorMode.position:
        final progressX = position.x / params.canvasSize.width;
        final progressY = position.y / params.canvasSize.height;
        final progress = (progressX + progressY) / 2;
        return colorPalette.getColorAtProgress(progress);
      
      case ColorMode.gradient:
        final progress = position.y / params.canvasSize.height;
        return colorPalette.getColorAtProgress(progress);
      
      case ColorMode.random:
        return colorPalette.getRandomColor();
      
      case ColorMode.single:
      case ColorMode.velocity:
      case ColorMode.age:
      case ColorMode.custom:
        if (colorPalette.colors.isEmpty) {
          return Colors.white.withOpacity(colorPalette.opacity);
        }
        return colorPalette.colors.first.withOpacity(colorPalette.opacity);
    }
  }
  
  /// Update all particles
  void update() {
    // Apply movement behavior forces to all particles
    _applyMovementBehavior();
    
    // Apply interaction forces if enabled
    if (params.interactionEnabled && interactionPoint != null) {
      _applyInteractionForce();
    }
    
    // Update each particle and replace dead ones
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(params);
      
      // Update color for specific color modes
      _updateParticleColor(particles[i]);
      
      // If particle is dead, replace it
      if (!particles[i].isAlive()) {
        particles[i] = _createReplacementParticle();
      }
    }
    
    // Handle collisions if enabled
    if (params.enableCollisions) {
      _handleCollisions();
    }
  }
  
  /// Apply appropriate forces based on movement behavior
  void _applyMovementBehavior() {
    switch (params.movementBehavior) {
      case MovementBehavior.orbit:
        _applyOrbitBehavior();
        break;
        
      case MovementBehavior.wave:
        _applyWaveBehavior();
        break;
        
      case MovementBehavior.follow:
        _applyFollowBehavior();
        break;
        
      case MovementBehavior.attract:
        _applyAttractBehavior(true);
        break;
        
      case MovementBehavior.repel:
        _applyAttractBehavior(false);
        break;
        
      case MovementBehavior.random:
        _applyRandomForces();
        break;
        
      case MovementBehavior.directed:
      case MovementBehavior.bounce:
      default:
        // These behaviors rely on initial velocities and edge handling
        break;
    }
  }
  
  /// Apply orbit behavior forces
  void _applyOrbitBehavior() {
    final centerX = params.canvasSize.width / 2;
    final centerY = params.canvasSize.height / 2;
    final center = Vector2(centerX, centerY);
    
    for (var particle in particles) {
      // Vector toward center
      final toCenter = center - particle.position;
      final distance = toCenter.length;
      
      if (distance > 0) {
        // Normalized direction to center
        toCenter.normalize();
        
        // Centripetal force for orbit
        final centripetalForce = toCenter * (0.01 * distance);
        particle.applyForce(centripetalForce);
        
        // Perpendicular force for orbit
        final perpendicular = Vector2(-toCenter.y, toCenter.x);
        final orbitForce = perpendicular * 0.1;
        particle.applyForce(orbitForce);
      }
    }
  }
  
  /// Apply wave-like behavior forces
  void _applyWaveBehavior() {
    final time = DateTime.now().millisecondsSinceEpoch * 0.001;
    
    for (var particle in particles) {
      // Sine wave force on y-axis
      final frequency = 0.005;
      final amplitude = 0.1;
      final phase = particle.position.x * frequency + time;
      final verticalForce = sin(phase) * amplitude;
      
      particle.applyForce(Vector2(0.01, verticalForce));
    }
  }
  
  /// Apply flocking/following behavior
  void _applyFollowBehavior() {
    // Simplified flocking algorithm with separation, alignment and cohesion
    
    if (particles.isEmpty) return;
    
    // Parameters for flocking behavior
    const perceptionRadius = 50.0;
    const separationFactor = 0.05;
    const alignmentFactor = 0.02;
    const cohesionFactor = 0.01;
    
    for (var particle in particles) {
      final Vector2 separation = Vector2(0, 0);
      final Vector2 alignment = Vector2(0, 0);
      final Vector2 cohesion = Vector2(0, 0);
      int count = 0;
      
      // Check against other particles
      for (var other in particles) {
        if (identical(particle, other)) continue;
        
        final distance = particle.distanceTo(other);
        
        if (distance < perceptionRadius) {
          // Separation: steer away from nearby particles
          final diff = particle.position - other.position;
          diff.normalize();
          diff.scale(1.0 / max(distance, 1.0));
          separation.add(diff);
          
          // Alignment: steer towards average direction
          alignment.add(other.velocity);
          
          // Cohesion: steer toward average position
          cohesion.add(other.position);
          
          count++;
        }
      }
      
      if (count > 0) {
        // Calculate average forces
        separation.scale(separationFactor);
        
        alignment.scale(1.0 / count);
        alignment.normalize();
        alignment.scale(alignmentFactor);
        
        cohesion.scale(1.0 / count);
        cohesion.sub(particle.position);
        cohesion.normalize();
        cohesion.scale(cohesionFactor);
        
        // Apply forces
        particle.applyForce(separation);
        particle.applyForce(alignment);
        particle.applyForce(cohesion);
      }
    }
  }
  
  /// Apply attraction or repulsion behavior
  void _applyAttractBehavior(bool attract) {
    final centerX = params.canvasSize.width / 2;
    final centerY = params.canvasSize.height / 2;
    final center = Vector2(centerX, centerY);
    final factor = attract ? 0.05 : -0.05;
    
    for (var particle in particles) {
      final direction = center - particle.position;
      final distance = direction.length;
      
      if (distance > 0) {
        // Force diminishes with distance
        final strength = factor / (1 + distance * 0.01);
        direction.normalize();
        direction.scale(strength);
        
        particle.applyForce(direction);
      }
    }
  }
  
  /// Apply random forces to create chaotic movement
  void _applyRandomForces() {
    for (var particle in particles) {
      if (random.nextDouble() < 0.05) {
        final forceX = (random.nextDouble() * 2 - 1) * 0.1;
        final forceY = (random.nextDouble() * 2 - 1) * 0.1;
        particle.applyForce(Vector2(forceX, forceY));
      }
    }
  }
  
  /// Apply forces based on user interaction point
  void _applyInteractionForce() {
    if (interactionPoint == null) return;
    
    final interactionVector = Vector2(interactionPoint!.dx, interactionPoint!.dy);
    final radius = params.interactionRadius;
    final strength = params.interactionStrength;
    
    for (var particle in particles) {
      final direction = interactionVector - particle.position;
      final distance = direction.length;
      
      if (distance < radius && distance > 0) {
        // Force diminishes with distance
        final forceFactor = 1.0 - (distance / radius);
        direction.normalize();
        direction.scale(forceFactor * strength * 0.1);
        
        particle.applyForce(direction);
      }
    }
  }
  
  /// Update particle color for velocity and age-based color modes
  void _updateParticleColor(Particle particle) {
    final colorPalette = params.colorPalette;
    
    switch (colorPalette.colorMode) {
      case ColorMode.velocity:
        // Color based on velocity magnitude
        final speed = particle.velocity.length;
        final maxSpeed = 5.0; // Arbitrary maximum speed
        final progress = min(1.0, speed / maxSpeed);
        particle.color = colorPalette.getColorAtProgress(progress);
        break;
        
      case ColorMode.age:
        // Color changes with particle age
        final progress = particle.getAgeProgress();
        particle.color = colorPalette.getColorAtProgress(progress);
        break;
        
      case ColorMode.position:
      case ColorMode.gradient:
      case ColorMode.random:
      case ColorMode.single:
      case ColorMode.custom:
        // Other color modes are handled at creation time
        break;
    }
  }
  
  /// Handle collisions between particles
  void _handleCollisions() {
    // Simple collision detection with optimization for large particle counts
    if (particles.length > 1000) {
      // For large particle counts, only check a subset
      for (int i = 0; i < particles.length; i += 5) {
        _checkParticleCollisions(i);
      }
    } else {
      // Check all particles
      for (int i = 0; i < particles.length; i++) {
        _checkParticleCollisions(i);
      }
    }
  }
  
  /// Check and handle collisions for a single particle
  void _checkParticleCollisions(int index) {
    if (index >= particles.length) return;
    
    final particle = particles[index];
    
    // Check against a subset of other particles
    for (int j = (index + 1) % 3; j < particles.length; j += 3) {
      final other = particles[j];
      
      // Calculate distance between particles
      final dx = particle.position.x - other.position.x;
      final dy = particle.position.y - other.position.y;
      final distance = sqrt(dx * dx + dy * dy);
      
      // Check collision based on particle sizes
      final minDist = (particle.size + other.size) / 2;
      
      if (distance < minDist && distance > 0) {
        // Simple collision response
        final angle = atan2(dy, dx);
        final targetX = particle.position.x + cos(angle) * minDist;
        final targetY = particle.position.y + sin(angle) * minDist;
        
        // Calculate displacement
        final ax = (targetX - other.position.x) * 0.05;
        final ay = (targetY - other.position.y) * 0.05;
        
        // Apply forces in opposite directions
        particle.applyForce(Vector2(ax, ay));
        other.applyForce(Vector2(-ax, -ay));
      }
    }
  }
  
  /// Create a replacement particle for ones that died
  Particle _createReplacementParticle() {
    // Strategy for replacement depends on movement behavior
    Vector2 position;
    
    switch (params.movementBehavior) {
      case MovementBehavior.directed:
        // Appear from one edge
        final side = random.nextInt(4);
        switch (side) {
          case 0: // top
            position = Vector2(
              random.nextDouble() * params.canvasSize.width, 
              -params.maxParticleSize
            );
            break;
          case 1: // right
            position = Vector2(
              params.canvasSize.width + params.maxParticleSize,
              random.nextDouble() * params.canvasSize.height
            );
            break;
          case 2: // bottom
            position = Vector2(
              random.nextDouble() * params.canvasSize.width,
              params.canvasSize.height + params.maxParticleSize
            );
            break;
          case 3: // left
          default:
            position = Vector2(
              -params.maxParticleSize,
              random.nextDouble() * params.canvasSize.height
            );
            break;
        }
        break;
        
      default:
        // For most behaviors, initialize a completely new particle
        position = _getInitialPosition();
        break;
    }
    
    final velocity = _getInitialVelocity();
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
  
  /// Update parameter settings
  void updateParameters(ParameterSet newParams) {
    bool needsReinit = 
        newParams.algorithmType != params.algorithmType ||
        newParams.particleCount != params.particleCount ||
        newParams.particleShape != params.particleShape ||
        newParams.movementBehavior != params.movementBehavior;
    
    params = newParams;
    
    if (needsReinit) {
      _initializeParticles();
    }
  }
  
  /// Set the interaction point
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  /// Render all particles to the canvas
  void render(Canvas canvas) {
    for (var particle in particles) {
      particle.render(canvas, params);
    }
  }
  
  /// Handle particle boundaries based on movement behavior
  void _handleBoundaries(Particle particle) {
    final position = particle.position;
    final velocity = particle.velocity;
    final size = particle.size;
    final width = params.canvasSize.width;
    final height = params.canvasSize.height;

    switch (params.movementBehavior) {
      case MovementBehavior.bounce:
        // Bounce off edges
        if (position.x < 0 || position.x > width) {
          velocity.x *= -params.bounceFactor;
          position.x = (position.x < 0) ? 0 : width;
        }
        if (position.y < 0 || position.y > height) {
          velocity.y *= -params.bounceFactor;
          position.y = (position.y < 0) ? 0 : height;
        }
        break;
      
      case MovementBehavior.follow:
      case MovementBehavior.directed:
      case MovementBehavior.random:
      case MovementBehavior.orbit:
      case MovementBehavior.wave:
      case MovementBehavior.attract:
      case MovementBehavior.repel:
        // Wrap around edges
        if (position.x < -size) position.x = width + size;
        if (position.x > width + size) position.x = -size;
        if (position.y < -size) position.y = height + size;
        if (position.y > height + size) position.y = -size;
        break;
    }
  }
}