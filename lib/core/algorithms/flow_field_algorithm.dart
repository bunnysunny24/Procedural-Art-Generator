import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/core/algorithms/generative_algorithm.dart';
import 'package:myapp/core/models/parameter_set.dart';
import 'package:myapp/core/models/color_palette.dart';

/// A particle in the flow field
class FlowParticle {
  /// Current position
  Offset position;
  
  /// Current velocity
  Offset velocity;
  
  /// Current acceleration
  Offset acceleration = Offset.zero;
  
  /// Maximum speed
  final double maxSpeed;
  
  /// Particle color
  Color color;
  
  /// Particle age in seconds
  double age = 0;
  
  /// Maximum lifetime in seconds
  final double maxLifetime;
  
  /// Size of the particle
  double size;
  
  /// History of positions for trail rendering
  final List<Offset> history;
  
  /// Maximum history length
  final int maxHistory;
  
  /// Whether the particle is alive
  bool get isAlive => age < maxLifetime;
  
  /// Creates a new flow particle
  FlowParticle({
    required this.position,
    required this.velocity,
    required this.maxSpeed,
    required this.color,
    required this.maxLifetime,
    required this.size,
    required this.maxHistory,
  }) : history = [position];
  
  /// Update the particle state
  void update(double deltaTime, Function(Offset) getForce) {
    // Apply flow field force
    acceleration = getForce(position);
    
    // Update velocity
    velocity += acceleration * deltaTime;
    
    // Limit speed
    if (velocity.distance > maxSpeed) {
      velocity = Offset(velocity.dx, velocity.dy) * (maxSpeed / velocity.distance);
    }
    
    // Update position
    position += velocity * deltaTime;
    
    // Record history for trails
    history.add(position);
    if (history.length > maxHistory) {
      history.removeAt(0);
    }
    
    // Update age
    age += deltaTime;
  }
}

/// Flow Field algorithm implementation
class FlowFieldAlgorithm extends GenerativeAlgorithm {
  /// Random generator
  final Random _random = Random();
  
  /// List of particles
  final List<FlowParticle> _particles = [];
  
  /// Resolution of the flow field grid
  late int _gridResolutionX;
  late int _gridResolutionY;
  
  /// Cell size
  late double _cellWidth;
  late double _cellHeight;
  
  /// Flow field vectors
  late List<List<double>> _flowField;
  
  /// Noise parameters
  double _noiseScale = 0.01;
  double _noiseStrength = 1.0;
  double _noiseZ = 0.0;
  double _noiseTurbulence = 0.5;
  
  /// Creates a new flow field algorithm
  FlowFieldAlgorithm(ParameterSet parameters) : super(parameters) {
    initialize();
  }
  
  @override
  void initialize() {
    // Clear existing particles
    _particles.clear();
    
    // Initialize flow field parameters based on parameter set
    _noiseScale = parameters.getDouble('noiseScale', 0.01);
    _noiseStrength = parameters.getDouble('fieldStrength', 1.0);
    _noiseTurbulence = parameters.getDouble('turbulence', 0.5);
    
    // Setup flow field grid
    _gridResolutionX = parameters.getInt('gridResolutionX', 50);
    _gridResolutionY = parameters.getInt('gridResolutionY', 50);
    
    _cellWidth = parameters.canvasSize.width / _gridResolutionX;
    _cellHeight = parameters.canvasSize.height / _gridResolutionY;
    
    // Initialize flow field
    _flowField = List.generate(
      _gridResolutionX,
      (_) => List.generate(_gridResolutionY, (_) => 0.0)
    );
    
    // Generate initial flow field
    _generateFlowField();
    
    // Create initial particles
    _createParticles(parameters.getInt('particleCount', 500));
  }

  @override
  void onParametersUpdated() {
    initialize();
  }
  
  /// Generate the flow field
  void _generateFlowField() {
    for (int x = 0; x < _gridResolutionX; x++) {
      for (int y = 0; y < _gridResolutionY; y++) {
        // Use Perlin noise or a similar algorithm to generate the flow field
        // For simplicity, using a simple mathematical function here
        final value = _simpleNoise(x * _noiseScale, y * _noiseScale, _noiseZ) * 2 * pi;
        _flowField[x][y] = value;
      }
    }
  }
  
  /// Simple noise function (replace with Perlin noise for better results)
  double _simpleNoise(double x, double y, double z) {
    // Simple noise function based on sine waves
    // In production, use a library that provides Perlin/Simplex noise
    return sin(x * _noiseTurbulence + z) * cos(y * _noiseTurbulence + z) * 0.5 + 0.5;
  }
  
  /// Create particles
  void _createParticles(int count) {
    final maxSpeed = parameters.getDouble('maxSpeed', 100);
    final particleSize = parameters.getDouble('particleSize', 3);
    final maxLifetime = parameters.getDouble('particleLifetime', 10);
    final trailLength = parameters.getInt('trailLength', 20);
    
    for (int i = 0; i < count; i++) {
      // Random position within canvas
      final position = Offset(
        _random.nextDouble() * parameters.canvasSize.width,
        _random.nextDouble() * parameters.canvasSize.height
      );
      
      // Initial velocity (could be random or based on the flow field)
      final velocity = Offset(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1
      ) * (maxSpeed * 0.5);
      
      // Color based on position or random
      final colorProgress = position.dx / parameters.canvasSize.width;
      Color color;
      
      switch (parameters.colorPalette.colorMode) {
        case ColorMode.random:
          color = parameters.colorPalette.getRandomColor();
          break;
        case ColorMode.position:
          color = parameters.colorPalette.getColorAtProgress(colorProgress);
          break;
        default:
          color = parameters.colorPalette.getColorAtProgress(colorProgress);
      }
      
      // Create and add particle
      _particles.add(FlowParticle(
        position: position,
        velocity: velocity,
        maxSpeed: maxSpeed,
        color: color,
        maxLifetime: maxLifetime,
        size: particleSize,
        maxHistory: trailLength,
      ));
    }
  }
  
  @override
  void update(double deltaTime) {
    // Limit delta time to prevent large jumps
    final dt = min(deltaTime, 1/30);
    
    // Update noise z dimension for field animation
    if (parameters.getBool('animateField', true)) {
      _noiseZ += parameters.getDouble('fieldAnimationSpeed', 0.1) * dt;
      _generateFlowField();
    }
    
    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      
      // Update particle
      particle.update(dt, _getFlowFieldForce);
      
      // Remove dead particles
      if (!particle.isAlive) {
        _particles.removeAt(i);
      }
    }
    
    // Add new particles if needed to maintain count
    final targetCount = parameters.getInt('particleCount', 500);
    if (_particles.length < targetCount) {
      _createParticles(targetCount - _particles.length);
    }
  }
  
  /// Get the force for a particle at the given position
  Offset _getFlowFieldForce(Offset position) {
    // Get grid cell coordinates
    int x = (position.dx / _cellWidth).floor();
    int y = (position.dy / _cellHeight).floor();
    
    // Bounds check
    if (x < 0 || x >= _gridResolutionX || y < 0 || y >= _gridResolutionY) {
      // If out of bounds, return a force pushing back into the canvas
      final centerX = parameters.canvasSize.width / 2;
      final centerY = parameters.canvasSize.height / 2;
      return Offset(
        centerX - position.dx,
        centerY - position.dy,
      ).normalize() * _noiseStrength;
    }
    
    // Get angle from flow field
    final angle = _flowField[x][y];
    
    // Convert angle to vector
    return Offset(
      cos(angle),
      sin(angle)
    ) * _noiseStrength;
  }
  
  @override
  void render(Canvas canvas) {
    // Render each particle and its trail
    for (final particle in _particles) {
      // Skip rendering if it has too few history points
      if (particle.history.length < 2) continue;
      
      // Create trail gradient
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = particle.size
        ..strokeCap = StrokeCap.round;
      
      // Draw trail segments with gradually increasing transparency
      for (int i = 0; i < particle.history.length - 1; i++) {
        final progress = i / (particle.history.length - 1);
        final opacityFactor = progress * parameters.getDouble('trailOpacity', 0.5);
        
        trailPaint.color = particle.color.withOpacity(opacityFactor);
        
        canvas.drawLine(
          particle.history[i],
          particle.history[i + 1],
          trailPaint
        );
      }
      
      // Draw particle head
      final particlePaint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        particle.position,
        particle.size,
        particlePaint
      );
    }
    
    // Draw flow field for debugging if enabled
    if (parameters.getBool('showFlowField', false)) {
      _renderFlowField(canvas);
    }
  }
  
  /// Render the flow field for visualization/debugging
  void _renderFlowField(Canvas canvas) {
    final fieldPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw a small line in each cell representing the flow direction
    for (int x = 0; x < _gridResolutionX; x += 3) {
      for (int y = 0; y < _gridResolutionY; y += 3) {
        final centerX = x * _cellWidth + _cellWidth / 2;
        final centerY = y * _cellHeight + _cellHeight / 2;
        final center = Offset(centerX, centerY);
        
        final angle = _flowField[x][y];
        final length = _cellWidth * 0.4; // Length of the line
        
        final endpoint = Offset(
          centerX + cos(angle) * length,
          centerY + sin(angle) * length
        );
        
        canvas.drawLine(center, endpoint, fieldPaint);
      }
    }
  }
  
  @override
  void handleInteraction(Offset position, bool isActive) {
    if (!isActive) return;
    
    // Add some particles at the interaction point
    final interactionRadius = parameters.getDouble('interactionRadius', 50);
    final particleBurst = parameters.getInt('interactionParticles', 10);
    
    for (int i = 0; i < particleBurst; i++) {
      // Create particles in a radius around the interaction point
      final angle = _random.nextDouble() * 2 * pi;
      final distance = _random.nextDouble() * interactionRadius;
      
      final particlePos = Offset(
        position.dx + cos(angle) * distance,
        position.dy + sin(angle) * distance
      );
      
      // Skip if outside canvas bounds
      if (particlePos.dx < 0 || 
          particlePos.dx > parameters.canvasSize.width ||
          particlePos.dy < 0 || 
          particlePos.dy > parameters.canvasSize.height) {
        continue;
      }
      
      // Create particle with random velocity
      final velocity = Offset(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1
      ) * (parameters.getDouble('maxSpeed', 100) * 0.5);
      
      // Get color based on position or random based on color mode
      final colorProgress = particlePos.dx / parameters.canvasSize.width;
      final color = parameters.colorPalette.getColorAtProgress(colorProgress);
      
      // Add new particle
      _particles.add(FlowParticle(
        position: particlePos,
        velocity: velocity,
        maxSpeed: parameters.getDouble('maxSpeed', 100),
        color: color,
        maxLifetime: parameters.getDouble('particleLifetime', 10),
        size: parameters.getDouble('particleSize', 3),
        maxHistory: parameters.getInt('trailLength', 20),
      ));
      
      // Optionally, add some turbulence to the flow field around the interaction point
      if (parameters.getBool('interactionAffectsField', true)) {
        // Create a ripple effect in the flow field
        // This could be improved with a more sophisticated approach
        _addRippleToFlowField(position);
      }
    }
  }
  
  /// Adds a ripple effect to the flow field around the specified position
  void _addRippleToFlowField(Offset position) {
    final rippleRadius = parameters.getDouble('rippleRadius', 100);
    final rippleStrength = parameters.getDouble('rippleStrength', 0.5);
    
    // Get grid cell of the center of the ripple
    final centerX = position.dx / _cellWidth;
    final centerY = position.dy / _cellHeight;
    
    // Calculate cells affected by the ripple
    final cellRadius = (rippleRadius / _cellWidth).ceil();
    
    // Apply ripple to all cells within radius
    for (int x = 0; x < _gridResolutionX; x++) {
      for (int y = 0; y < _gridResolutionY; y++) {
        // Calculate distance from ripple center
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        
        if (distance < cellRadius) {
          // Calculate angle pointing away from ripple center
          final angle = atan2(dy, dx);
          
          // Calculate ripple effect strength based on distance
          final effect = (1 - distance / cellRadius) * rippleStrength;
          
          // Blend current flow field angle with ripple angle
          _flowField[x][y] = _flowField[x][y] * (1 - effect) + angle * effect;
        }
      }
    }
  }
}