import 'dart:math';
import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';

class ParticleSystemAlgorithm extends GenerativeAlgorithm {
  final List<Particle> _particles = [];
  final Random _random = Random();
  
  ParticleSystemAlgorithm(ParameterSet parameters) : super(parameters) {
    _initialize();
  }

  void _initialize() {
    _particles.clear();
    for (int i = 0; i < parameters.particleCount; i++) {
      _createParticle();
    }
  }

  @override
  void update(Duration delta) {
    final dt = delta.inMilliseconds / 1000.0;
    _updateParticles(dt);
    if (parameters.enableCollisions) {
      _handleCollisions();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & parameters.canvasSize,
      Paint()..color = parameters.backgroundColor,
    );

    for (final particle in _particles) {
      _renderParticle(canvas, particle);
    }
  }

  @override
  void handleInput(Offset position, bool isActive) {
    if (!isActive) return;
    _applyInteractionForce(position);
  }

  @override
  void reset() {
    _initialize();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    if (_needsReset(newParameters)) {
      _initialize();
    }
  }

  bool _needsReset(ParameterSet newParameters) {
    return newParameters.particleCount != parameters.particleCount ||
           newParameters.particleShape != parameters.particleShape ||
           newParameters.movementBehavior != parameters.movementBehavior;
  }

  void _updateParticles(double dt) {
    for (final particle in _particles) {
      // Apply forces
      if (parameters.gravity != 0) {
        particle.applyForce(Vector2(0, parameters.gravity));
      }
      if (parameters.wind != 0) {
        particle.applyForce(Vector2(parameters.wind, 0));
      }
      
      // Update position
      particle.update(dt);
      
      // Apply boundaries
      _handleBoundaries(particle);
    }
  }

  void _handleBoundaries(Particle particle) {
    final size = parameters.maxParticleSize;
    final width = parameters.canvasSize.width;
    final height = parameters.canvasSize.height;

    if (particle.position.x < -size) particle.position.x = width + size;
    if (particle.position.x > width + size) particle.position.x = -size;
    if (particle.position.y < -size) particle.position.y = height + size;
    if (particle.position.y > height + size) particle.position.y = -size;
  }

  void _handleCollisions() {
    for (int i = 0; i < _particles.length; i++) {
      for (int j = i + 1; j < _particles.length; j++) {
        final p1 = _particles[i];
        final p2 = _particles[j];
        
        final dx = p2.position.x - p1.position.x;
        final dy = p2.position.y - p1.position.y;
        final distance = sqrt(dx * dx + dy * dy);
        
        final minDist = (p1.size + p2.size) / 2;
        if (distance < minDist && distance > 0) {
          final angle = atan2(dy, dx);
          final force = (minDist - distance) * parameters.bounceFactor;
          
          final forceX = cos(angle) * force;
          final forceY = sin(angle) * force;
          
          p1.applyForce(Vector2(-forceX, -forceY));
          p2.applyForce(Vector2(forceX, forceY));
        }
      }
    }
  }

  void _applyInteractionForce(Offset point) {
    final interactionPos = Vector2(point.dx, point.dy);
    
    for (final particle in _particles) {
      final direction = interactionPos - particle.position;
      final distance = direction.length;
      
      if (distance < parameters.interactionRadius && distance > 0) {
        direction.normalize();
        final force = 1.0 - (distance / parameters.interactionRadius);
        direction.scale(force * parameters.interactionStrength);
        particle.applyForce(direction);
      }
    }
  }

  void _createParticle() {
    _particles.add(Particle(
      position: Vector2(
        _random.nextDouble() * parameters.canvasSize.width,
        _random.nextDouble() * parameters.canvasSize.height,
      ),
      velocity: _getInitialVelocity(),
      size: _getRandomSize(),
      color: _getParticleColor(Vector2.zero()),
      shape: parameters.particleShape,
    ));
  }

  Vector2 _getInitialVelocity() {
    final speed = _random.nextDouble() * 2 - 1;
    final angle = _random.nextDouble() * 2 * pi;
    return Vector2(cos(angle) * speed, sin(angle) * speed);
  }

  double _getRandomSize() {
    return parameters.minParticleSize +
           _random.nextDouble() * (parameters.maxParticleSize - parameters.minParticleSize);
  }

  Color _getParticleColor(Vector2 position) {
    final progress = position.y / parameters.canvasSize.height;
    return parameters.colorPalette.getColorAtProgress(progress);
  }

  void _renderParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.color
      ..style = PaintingStyle.fill;

    final pos = Offset(particle.position.x, particle.position.y);
    
    switch (particle.shape) {
      case ParticleShape.circle:
        canvas.drawCircle(pos, particle.size / 2, paint);
        break;
      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: pos, width: particle.size, height: particle.size),
          paint,
        );
        break;
      case ParticleShape.triangle:
        _drawTriangle(canvas, pos, particle.size, paint);
        break;
      case ParticleShape.line:
        final angle = atan2(particle.velocity.y, particle.velocity.x);
        _drawLine(canvas, pos, particle.size, angle, paint);
        break;
      case ParticleShape.custom:
        _drawStar(canvas, pos, particle.size, paint);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final height = size * sqrt(3) / 2;
    
    path.moveTo(center.dx, center.dy - height / 2);
    path.lineTo(center.dx - size / 2, center.dy + height / 2);
    path.lineTo(center.dx + size / 2, center.dy + height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Offset center, double size, double angle, Paint paint) {
    final dx = cos(angle) * size / 2;
    final dy = sin(angle) * size / 2;
    
    canvas.drawLine(
      Offset(center.dx - dx, center.dy - dy),
      Offset(center.dx + dx, center.dy + dy),
      paint..strokeWidth = size / 4,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;
    const points = 5;
    
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = i * pi / points;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
}

class Particle {
  Vector2 position;
  Vector2 velocity;
  final double size;
  final Color color;
  final ParticleShape shape;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.shape,
  });

  void update(double dt) {
    position += velocity * dt;
  }

  void applyForce(Vector2 force) {
    velocity += force;
  }
}