import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'parameter_set.dart';

/// Represents an individual particle in a particle system
class Particle {
  /// Current position of the particle
  Vector2 position;
  
  /// Current velocity of the particle
  Vector2 velocity;
  
  /// Current acceleration of the particle
  Vector2 acceleration;
  
  /// Size of the particle (can be interpreted as radius or side length)
  double size;
  
  /// Color of the particle
  Color color;
  
  /// Current rotation angle in radians
  double rotation;
  
  /// Speed of rotation in radians per update
  double rotationSpeed;
  
  /// Current particle age (0.0 to 1.0, where 1.0 is full life span)
  double life;
  
  /// Rate at which particle life declines per update
  double decay;
  
  /// Shape of this particle
  ParticleShape shape;
  
  /// Initial creation time
  final DateTime creationTime;
  
  /// Custom properties that can be used by specific algorithms
  final Map<String, dynamic> customProperties;

  Particle({
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.size,
    required this.color,
    required this.shape,
    this.rotation = 0.0,
    double? rotationSpeed,
    this.life = 1.0,
    double? decay,
    Map<String, dynamic>? customProperties,
  }) : 
    this.rotationSpeed = rotationSpeed ?? _generateRandomRotationSpeed(),
    this.decay = decay ?? 0.005,
    this.customProperties = customProperties ?? {},
    this.creationTime = DateTime.now();

  /// Updates the particle state based on the parameter set
  void update(ParameterSet params) {
    // Apply physics
    if (params.gravity != 0) {
      acceleration.y += params.gravity;
    }
    
    if (params.wind != 0) {
      acceleration.x += params.wind;
    }
    
    // Apply friction
    velocity.scale(1.0 - params.friction);
    
    // Apply turbulence if enabled
    if (params.turbulence > 0) {
      _applyTurbulence(params.turbulence);
    }
    
    // Update velocity and position
    velocity.add(acceleration);
    position.add(velocity.scaled(params.speed));
    
    // Reset acceleration for next frame
    acceleration.setZero();
    
    // Update rotation
    rotation += rotationSpeed;
    
    // Reduce life based on decay
    life -= decay;
    
    // Handle edge behavior based on movement behavior
    _handleEdgeBehavior(params);
  }
  
  /// Apply a force to the particle
  void applyForce(Vector2 force) {
    acceleration.add(force);
  }
  
  /// Apply turbulence to the particle
  void _applyTurbulence(double strength) {
    final noiseX = sin(position.y * 0.01 + DateTime.now().millisecondsSinceEpoch * 0.0001);
    final noiseY = cos(position.x * 0.01 + DateTime.now().millisecondsSinceEpoch * 0.0001);
    
    acceleration.add(Vector2(noiseX, noiseY) * strength * 0.1);
  }
  
  /// Handle behavior when particle reaches canvas edge
  void _handleEdgeBehavior(ParameterSet params) {
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
      default:
        // Wrap around edges for other behaviors
        if (position.x < -size) position.x = width + size;
        if (position.x > width + size) position.x = -size;
        if (position.y < -size) position.y = height + size;
        if (position.y > height + size) position.y = -size;
        break;
    }
  }
  
  /// Draw the particle on the canvas
  void render(Canvas canvas, ParameterSet params) {
    final paint = Paint()
      ..color = color.withOpacity(color.opacity * life)
      ..style = PaintingStyle.fill;
    
    // Apply blending if enabled
    if (params.particleBlending) {
      paint.blendMode = BlendMode.srcOver;
    }
    
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);
    
    // Draw based on shape
    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
        
      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size,
          ),
          paint,
        );
        break;
        
      case ParticleShape.triangle:
        final path = Path();
        final height = sin(pi / 3) * size;
        path.moveTo(0, -height / 2);
        path.lineTo(-size / 2, height / 2);
        path.lineTo(size / 2, height / 2);
        path.close();
        canvas.drawPath(path, paint);
        break;
        
      case ParticleShape.line:
        paint.strokeWidth = max(1.0, size / 5);
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(-size / 2, 0),
          Offset(size / 2, 0),
          paint,
        );
        break;
        
      case ParticleShape.custom:
        _drawCustomShape(canvas, paint, size);
        break;
    }
    
    canvas.restore();
  }
  
  /// Draw a custom particle shape
  void _drawCustomShape(Canvas canvas, Paint paint, double size) {
    // Default implementation draws a star
    final path = Path();
    final numPoints = 5;
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    
    for (int i = 0; i < numPoints * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = i * pi / numPoints;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  /// Check if particle is still alive
  bool isAlive() {
    return life > 0;
  }
  
  /// Get age as a normalized value from 0.0 to 1.0
  double getAgeProgress() {
    return 1.0 - life;
  }
  
  /// Calculate distance to another particle
  double distanceTo(Particle other) {
    return (position - other.position).length;
  }
  
  /// Generate a random rotation speed
  static double _generateRandomRotationSpeed() {
    final random = Random();
    return (random.nextDouble() * 0.1 - 0.05) * pi;
  }
}