import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'art_parameters.dart';
import 'particle.dart';

class ParticleSystem {
  final List<Particle> particles = [];
  final Random random = Random();
  late ArtParameters params;
  Offset? interactionPoint;
  
  ParticleSystem(this.params) {
    _initializeParticles();
  }
  
  void _initializeParticles() {
    particles.clear();
    
    for (int i = 0; i < params.particleCount; i++) {
      _createParticle();
    }
  }
  
  void _createParticle() {
    final position = _getInitialPosition();
    final velocity = _getInitialVelocity();
    final size = _getRandomSize();
    final color = _getParticleColor(position);
    
    particles.add(Particle(
      position: position,
      velocity: velocity,
      acceleration: Vector2(0, 0),
      size: size,
      color: color,
      type: params.particleType,
      decay: random.nextDouble() * 0.005 + 0.001,
    ));
  }
  
  Vector2 _getInitialPosition() {
    switch (params.animationType) {
      case AnimationType.explode:
        // Start from center
        return Vector2(
          params.canvasSize.width / 2,
          params.canvasSize.height / 2,
        );
      case AnimationType.flow:
      case AnimationType.swirl:
      case AnimationType.bounce:
      case AnimationType.random:
      default:
        // Random position
        return Vector2(
          random.nextDouble() * params.canvasSize.width,
          random.nextDouble() * params.canvasSize.height,
        );
    }
  }
  
  Vector2 _getInitialVelocity() {
    switch (params.animationType) {
      case AnimationType.explode:
        // Radial velocity from center
        final angle = random.nextDouble() * 2 * pi;
        final magnitude = random.nextDouble() * 2.0 + 0.5;
        return Vector2(cos(angle) * magnitude, sin(angle) * magnitude);
      
      case AnimationType.flow:
        // Horizontal flow with slight variation
        return Vector2(
          (random.nextDouble() * 2 - 1) * 0.5, 
          (random.nextDouble() * 2 - 1) * 0.1
        );
      
      case AnimationType.swirl:
        // Initial velocity for swirl effect
        final angle = random.nextDouble() * 2 * pi;
        return Vector2(sin(angle) * 0.5, cos(angle) * 0.5);
      
      case AnimationType.bounce:
        // Random velocity for bounce effect
        return Vector2(
          (random.nextDouble() * 2 - 1) * 2,
          (random.nextDouble() * 2 - 1) * 2
        );
      
      case AnimationType.random:
      default:
        // Random velocity
        return Vector2(
          (random.nextDouble() * 2 - 1) * 0.5,
          (random.nextDouble() * 2 - 1) * 0.5
        );
    }
  }
  
  double _getRandomSize() {
    return params.minParticleSize + 
      random.nextDouble() * (params.maxParticleSize - params.minParticleSize);
  }
  
  Color _getParticleColor(Vector2 position) {
    switch (params.colorMode) {
      case ColorMode.single:
        return params.primaryColor;
        
      case ColorMode.gradient:
        // Create gradient effect based on position
        final progress = position.y / params.canvasSize.height;
        return Color.lerp(params.primaryColor, params.secondaryColor, progress) 
            ?? params.primaryColor;
        
      case ColorMode.rainbow:
        // Cycle through hue values
        final hue = (position.x / params.canvasSize.width * 360) % 360;
        return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        
      case ColorMode.custom:
        // Pick a random color from custom colors
        if (params.customColors.isEmpty) {
          return Colors.white;
        }
        return params.customColors[random.nextInt(params.customColors.length)];
    }
  }
  
  void update() {
    // Apply animation behavior based on type
    _applyAnimationBehavior();
    
    // Apply interaction forces if enabled
    if (params.gestureEnabled && interactionPoint != null) {
      _applyInteractionForce();
    }
    
    // Update each particle
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(params);
      
      // If particle is dead, replace it
      if (!particles[i].isAlive()) {
        particles[i] = _createReplacementParticle();
      }
    }
    
    // Handle collisions if enabled
    if (params.collisionEnabled) {
      _handleCollisions();
    }
  }
  
  void _applyAnimationBehavior() {
    switch (params.animationType) {
      case AnimationType.swirl:
        // Create swirling effect
        for (var particle in particles) {
          final centerX = params.canvasSize.width / 2;
          final centerY = params.canvasSize.height / 2;
          
          final dx = particle.position.x - centerX;
          final dy = particle.position.y - centerY;
          final distance = sqrt(dx * dx + dy * dy);
          
          if (distance > 0) {
            final angle = atan2(dy, dx);
            final swirlFactor = 0.1; // Controls how tight the swirl is
            
            // Perpendicular force for swirling
            particle.applyForce(Vector2(
              -dy * swirlFactor / distance,
              dx * swirlFactor / distance,
            ));
            
            // Slight inward/outward force
            final radialFactor = sin(distance * 0.01) * 0.02;
            particle.applyForce(Vector2(
              -dx * radialFactor / distance,
              -dy * radialFactor / distance,
            ));
          }
        }
        break;
        
      case AnimationType.flow:
        // Create flowing effect with sine wave motion
        for (var particle in particles) {
          final time = DateTime.now().millisecondsSinceEpoch * 0.001;
          final yOffset = sin(particle.position.x * 0.01 + time) * 0.1;
          particle.applyForce(Vector2(0.05, yOffset));
        }
        break;
        
      case AnimationType.random:
        // Random forces
        for (var particle in particles) {
          if (random.nextDouble() < 0.05) {
            particle.applyForce(Vector2(
              (random.nextDouble() * 2 - 1) * 0.2,
              (random.nextDouble() * 2 - 1) * 0.2,
            ));
          }
        }
        break;
        
      default:
        // Other animation types use the initial velocity setup
        break;
    }
  }
  
  void _applyInteractionForce() {
    if (interactionPoint == null) return;
    
    final interactionVector = Vector2(interactionPoint!.dx, interactionPoint!.dy);
    final interactionRadius = 100.0 * params.interactionStrength;
    
    for (var particle in particles) {
      final direction = interactionVector - particle.position;
      final distance = direction.length;
      
      if (distance < interactionRadius && distance > 0) {
        // Normalize and scale force based on distance
        direction.normalize();
        final force = 1.0 - (distance / interactionRadius);
        direction.scale(force * params.interactionStrength * 0.2);
        particle.applyForce(direction);
      }
    }
  }
  
  void _handleCollisions() {
    // Simple particle collision detection (optimization: spatial partitioning would be better for large numbers)
    if (particles.length > 1000) {
      // For large particle counts, only check a subset to avoid performance issues
      for (int i = 0; i < particles.length; i += 5) {
        _checkCollisionsForParticle(i);
      }
    } else {
      // Check all particles
      for (int i = 0; i < particles.length; i++) {
        _checkCollisionsForParticle(i);
      }
    }
  }
  
  void _checkCollisionsForParticle(int index) {
    if (index >= particles.length) return;
    
    final particle = particles[index];
    final collisionDistance = particle.size;
    
    // Check against a subset of other particles 
    for (int j = (index + 1) % 5; j < particles.length; j += 5) {
      final other = particles[j];
      final dx = particle.position.x - other.position.x;
      final dy = particle.position.y - other.position.y;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance < collisionDistance && distance > 0) {
        // Simple collision response
        final angle = atan2(dy, dx);
        final magnitude = (collisionDistance - distance) * 0.05;
        
        final forceX = cos(angle) * magnitude;
        final forceY = sin(angle) * magnitude;
        
        particle.applyForce(Vector2(forceX, forceY));
        other.applyForce(Vector2(-forceX, -forceY));
      }
    }
  }
  
  Particle _createReplacementParticle() {
    Vector2 position;
    
    switch (params.animationType) {
      case AnimationType.explode:
        // New particles emerge from center
        position = Vector2(
          params.canvasSize.width / 2, 
          params.canvasSize.height / 2
        );
        break;
        
      default:
        // Create new particles at edges
        final side = random.nextInt(4);
        switch (side) {
          case 0: // Top
            position = Vector2(
              random.nextDouble() * params.canvasSize.width,
              -5,
            );
            break;
          case 1: // Right
            position = Vector2(
              params.canvasSize.width + 5,
              random.nextDouble() * params.canvasSize.height,
            );
            break;
          case 2: // Bottom
            position = Vector2(
              random.nextDouble() * params.canvasSize.width,
              params.canvasSize.height + 5,
            );
            break;
          case 3: // Left
          default:
            position = Vector2(
              -5,
              random.nextDouble() * params.canvasSize.height,
            );
            break;
        }
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
      type: params.particleType,
    );
  }
  
  void updateParameters(ArtParameters newParams) {
    bool needsReinit = 
      newParams.particleType != params.particleType ||
      newParams.particleCount != params.particleCount ||
      newParams.animationType != params.animationType;
    
    params = newParams;
    
    if (needsReinit) {
      _initializeParticles();
    }
  }
  
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  void render(Canvas canvas) {
    for (var particle in particles) {
      particle.render(canvas);
    }
  }
}