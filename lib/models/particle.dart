import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'art_parameters.dart';

class Particle {
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;
  double size;
  Color color;
  double rotation = 0.0;
  double rotationSpeed = 0.0;
  double life = 1.0; // 1.0 = full life, 0.0 = dead
  double decay = 0.005; // How fast the particle decays
  ParticleType type;

  Particle({
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.size,
    required this.color,
    required this.type,
    double? rotationSpeed,
    double? decay,
  }) : 
    this.rotationSpeed = rotationSpeed ?? Random().nextDouble() * 0.1 - 0.05,
    this.decay = decay ?? 0.005;

  void update(ArtParameters params) {
    // Apply physics
    if (params.gravity != 0) {
      acceleration.y += params.gravity;
    }

    if (params.wind != 0) {
      acceleration.x += params.wind;
    }

    // Apply friction
    velocity.scale(1.0 - params.friction);
    
    // Apply turbulence
    if (params.turbulence > 0) {
      final turbulenceX = sin(position.y * 0.01) * params.turbulence;
      final turbulenceY = cos(position.x * 0.01) * params.turbulence;
      acceleration.add(Vector2(turbulenceX, turbulenceY));
    }

    // Update velocity and position
    velocity.add(acceleration);
    position.add(velocity.scaled(params.speed));
    
    // Reset acceleration
    acceleration.setZero();
    
    // Update rotation
    rotation += rotationSpeed;
    
    // Reduce life over time (for animations that use particle lifetime)
    life -= decay;
    
    // Handle edge wrapping or bouncing based on animation type
    _handleEdgeBehavior(params);
  }

  void _handleEdgeBehavior(ArtParameters params) {
    final width = params.canvasSize.width;
    final height = params.canvasSize.height;
    
    // Handle different behaviors based on animation type
    if (params.animationType == AnimationType.bounce) {
      // Bounce off edges
      if (position.x < 0 || position.x > width) {
        velocity.x *= -1;
        position.x = position.x < 0 ? 0 : width;
      }
      if (position.y < 0 || position.y > height) {
        velocity.y *= -1;
        position.y = position.y < 0 ? 0 : height;
      }
    } else {
      // Wrap around edges for other animation types
      if (position.x < -size) position.x = width + size;
      if (position.x > width + size) position.x = -size;
      if (position.y < -size) position.y = height + size;
      if (position.y > height + size) position.y = -size;
    }
  }

  void applyForce(Vector2 force) {
    acceleration.add(force);
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(life)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    switch (type) {
      case ParticleType.circle:
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
      case ParticleType.square:
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size,
          height: size,
        );
        canvas.drawRect(rect, paint);
        break;
      case ParticleType.triangle:
        final path = Path();
        final height = sin(pi / 3) * size;
        path.moveTo(0, -height / 2);
        path.lineTo(-size / 2, height / 2);
        path.lineTo(size / 2, height / 2);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case ParticleType.line:
        paint.strokeWidth = max(1.0, size / 5);
        paint.style = PaintingStyle.stroke;
        final lineLength = size;
        canvas.drawLine(
          Offset(-lineLength / 2, 0),
          Offset(lineLength / 2, 0),
          paint,
        );
        break;
      case ParticleType.custom:
        final path = Path();
        final numPoints = 5; // Star shape
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
        break;
    }

    canvas.restore();
  }
  
  bool isAlive() {
    return life > 0;
  }
}