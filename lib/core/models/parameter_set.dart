import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Defines the algorithm type for art generation
enum AlgorithmType {
  particleSystem,
  flowField,
  fractal,
  cellularAutomata,
  voronoi,
  waveFunctionCollapse
}

/// Defines the particle shape for particle-based algorithms
enum ParticleShape {
  circle,
  square,
  triangle,
  line,
  custom
}

/// Defines movement behaviors for particles
enum MovementBehavior {
  random,
  directed,
  follow,
  orbit,
  attract,
  repel,
  bounce,
  wave
}

/// Contains all parameters for generating procedural art
class ParameterSet extends Equatable {
  // Algorithm parameters
  final AlgorithmType algorithmType;
  final Map<String, dynamic> algorithmSpecificParams;
  
  // Canvas parameters
  final Size canvasSize;
  final Color backgroundColor;
  
  // Particle parameters (for particle-based algorithms)
  final ParticleShape particleShape;
  final int particleCount;
  final double minParticleSize;
  final double maxParticleSize;
  final double particleOpacity;
  final bool particleBlending;
  
  // Movement parameters
  final MovementBehavior movementBehavior;
  final double speed;
  final double turbulence;
  final double friction;
  
  // Physics parameters
  final double gravity;
  final double wind;
  final bool enableCollisions;
  final double bounceFactor;
  
  // Color parameters
  final ColorPalette colorPalette;
  
  // Interactive parameters
  final bool interactionEnabled;
  final double interactionStrength;
  final double interactionRadius;
  
  // Animation parameters
  final int animationFrameCount;
  final bool loopAnimation;
  final double frameRate;

  const ParameterSet({
    required this.algorithmType,
    this.algorithmSpecificParams = const {},
    required this.canvasSize,
    required this.backgroundColor,
    required this.particleShape,
    required this.particleCount,
    required this.minParticleSize,
    required this.maxParticleSize,
    required this.particleOpacity,
    required this.particleBlending,
    required this.movementBehavior,
    required this.speed,
    required this.turbulence,
    required this.friction,
    required this.gravity,
    required this.wind,
    required this.enableCollisions,
    required this.bounceFactor,
    required this.colorPalette,
    required this.interactionEnabled,
    required this.interactionStrength,
    required this.interactionRadius,
    required this.animationFrameCount,
    required this.loopAnimation,
    required this.frameRate,
  });

  /// Creates a default parameter set for initial state
  factory ParameterSet.defaultSettings() {
    return ParameterSet(
      algorithmType: AlgorithmType.particleSystem,
      canvasSize: const Size(800, 600),
      backgroundColor: Colors.black,
      particleShape: ParticleShape.circle,
      particleCount: 500,
      minParticleSize: 2.0,
      maxParticleSize: 10.0,
      particleOpacity: 0.8,
      particleBlending: true,
      movementBehavior: MovementBehavior.random,
      speed: 1.0,
      turbulence: 0.5,
      friction: 0.02,
      gravity: 0.0,
      wind: 0.0,
      enableCollisions: false,
      bounceFactor: 0.8,
      colorPalette: ColorPalette.defaultPalette(),
      interactionEnabled: true,
      interactionStrength: 1.0,
      interactionRadius: 100.0,
      animationFrameCount: 300,
      loopAnimation: true,
      frameRate: 60.0,
    );
  }

  /// Creates a copy with updated fields
  ParameterSet copyWith({
    AlgorithmType? algorithmType,
    Map<String, dynamic>? algorithmSpecificParams,
    Size? canvasSize,
    Color? backgroundColor,
    ParticleShape? particleShape,
    int? particleCount,
    double? minParticleSize,
    double? maxParticleSize,
    double? particleOpacity,
    bool? particleBlending,
    MovementBehavior? movementBehavior,
    double? speed,
    double? turbulence,
    double? friction,
    double? gravity,
    double? wind,
    bool? enableCollisions,
    double? bounceFactor,
    ColorPalette? colorPalette,
    bool? interactionEnabled,
    double? interactionStrength,
    double? interactionRadius,
    int? animationFrameCount,
    bool? loopAnimation,
    double? frameRate,
  }) {
    return ParameterSet(
      algorithmType: algorithmType ?? this.algorithmType,
      algorithmSpecificParams: algorithmSpecificParams ?? this.algorithmSpecificParams,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      particleShape: particleShape ?? this.particleShape,
      particleCount: particleCount ?? this.particleCount,
      minParticleSize: minParticleSize ?? this.minParticleSize,
      maxParticleSize: maxParticleSize ?? this.maxParticleSize,
      particleOpacity: particleOpacity ?? this.particleOpacity,
      particleBlending: particleBlending ?? this.particleBlending,
      movementBehavior: movementBehavior ?? this.movementBehavior,
      speed: speed ?? this.speed,
      turbulence: turbulence ?? this.turbulence,
      friction: friction ?? this.friction,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      enableCollisions: enableCollisions ?? this.enableCollisions,
      bounceFactor: bounceFactor ?? this.bounceFactor,
      colorPalette: colorPalette ?? this.colorPalette,
      interactionEnabled: interactionEnabled ?? this.interactionEnabled,
      interactionStrength: interactionStrength ?? this.interactionStrength,
      interactionRadius: interactionRadius ?? this.interactionRadius,
      animationFrameCount: animationFrameCount ?? this.animationFrameCount,
      loopAnimation: loopAnimation ?? this.loopAnimation,
      frameRate: frameRate ?? this.frameRate,
    );
  }

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'algorithmType': algorithmType.index,
      'algorithmSpecificParams': algorithmSpecificParams,
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'backgroundColor': backgroundColor.value,
      'particleShape': particleShape.index,
      'particleCount': particleCount,
      'minParticleSize': minParticleSize,
      'maxParticleSize': maxParticleSize,
      'particleOpacity': particleOpacity,
      'particleBlending': particleBlending,
      'movementBehavior': movementBehavior.index,
      'speed': speed,
      'turbulence': turbulence,
      'friction': friction,
      'gravity': gravity,
      'wind': wind,
      'enableCollisions': enableCollisions,
      'bounceFactor': bounceFactor,
      'colorPalette': colorPalette.toJson(),
      'interactionEnabled': interactionEnabled,
      'interactionStrength': interactionStrength,
      'interactionRadius': interactionRadius,
      'animationFrameCount': animationFrameCount,
      'loopAnimation': loopAnimation,
      'frameRate': frameRate,
    };
  }

  /// Creates from JSON
  factory ParameterSet.fromJson(Map<String, dynamic> json) {
    return ParameterSet(
      algorithmType: AlgorithmType.values[json['algorithmType']],
      algorithmSpecificParams: 
          json['algorithmSpecificParams'] as Map<String, dynamic>? ?? {},
      canvasSize: Size(
        json['canvasWidth'].toDouble(), 
        json['canvasHeight'].toDouble()
      ),
      backgroundColor: Color(json['backgroundColor']),
      particleShape: ParticleShape.values[json['particleShape']],
      particleCount: json['particleCount'],
      minParticleSize: json['minParticleSize'].toDouble(),
      maxParticleSize: json['maxParticleSize'].toDouble(),
      particleOpacity: json['particleOpacity'].toDouble(),
      particleBlending: json['particleBlending'],
      movementBehavior: MovementBehavior.values[json['movementBehavior']],
      speed: json['speed'].toDouble(),
      turbulence: json['turbulence'].toDouble(),
      friction: json['friction'].toDouble(),
      gravity: json['gravity'].toDouble(),
      wind: json['wind'].toDouble(),
      enableCollisions: json['enableCollisions'],
      bounceFactor: json['bounceFactor'].toDouble(),
      colorPalette: ColorPalette.fromJson(json['colorPalette']),
      interactionEnabled: json['interactionEnabled'],
      interactionStrength: json['interactionStrength'].toDouble(),
      interactionRadius: json['interactionRadius'].toDouble(),
      animationFrameCount: json['animationFrameCount'],
      loopAnimation: json['loopAnimation'],
      frameRate: json['frameRate'].toDouble(),
    );
  }

  @override
  List<Object> get props => [
    algorithmType,
    algorithmSpecificParams,
    canvasSize,
    backgroundColor,
    particleShape,
    particleCount,
    minParticleSize,
    maxParticleSize,
    particleOpacity,
    particleBlending,
    movementBehavior,
    speed,
    turbulence,
    friction,
    gravity,
    wind,
    enableCollisions,
    bounceFactor,
    colorPalette,
    interactionEnabled,
    interactionStrength,
    interactionRadius,
    animationFrameCount,
    loopAnimation,
    frameRate,
  ];
}