import 'package:flutter/material.dart';
import 'dart:ui';
import '../algorithms/generative_algorithm.dart';

enum ColorMode {
  single,
  gradient,
  position,
  velocity,
  age,
  random,
  custom,
}

enum MovementBehavior {
  directed,
  orbit,
  wave,
  bounce,
  attract,
  repel,
  follow,
  random,
}

enum ParticleShape {
  circle,
  square,
  triangle,
  line,
  custom,
}

class ParameterSet {
  final Size canvasSize;
  final Color backgroundColor;
  final ColorPalette colorPalette;
  final int particleCount;
  final ParticleShape particleShape;
  final double minParticleSize;
  final double maxParticleSize;
  final double interactionRadius;
  final double interactionStrength;
  final bool enableCollisions;
  final double bounceFactor;
  final MovementBehavior movementBehavior;
  final double turbulence;
  final double friction;
  final double gravity;
  final double wind;
  final Map<String, dynamic> algorithmSpecificParams;
  final bool animate;
  final bool interactionEnabled;
  final double speed;
  final AlgorithmType algorithmType;

  const ParameterSet({
    required this.canvasSize,
    this.backgroundColor = const Color(0xFF000000),
    required this.colorPalette,
    this.particleCount = 1000,
    this.particleShape = ParticleShape.circle,
    this.minParticleSize = 2.0,
    this.maxParticleSize = 8.0,
    this.interactionRadius = 100.0,
    this.interactionStrength = 1.0,
    this.enableCollisions = false,
    this.bounceFactor = 0.5,
    this.movementBehavior = MovementBehavior.directed,
    this.turbulence = 0.0,
    this.friction = 0.0,
    this.gravity = 0.0,
    this.wind = 0.0,
    this.algorithmSpecificParams = const {},
    this.animate = true,
    this.interactionEnabled = true,
    this.speed = 1.0,
    this.algorithmType = AlgorithmType.particleSystem,
  });

  ParameterSet copyWith({
    Size? canvasSize,
    Color? backgroundColor,
    ColorPalette? colorPalette,
    int? particleCount,
    ParticleShape? particleShape,
    double? minParticleSize,
    double? maxParticleSize,
    double? interactionRadius,
    double? interactionStrength,
    bool? enableCollisions,
    double? bounceFactor,
    MovementBehavior? movementBehavior,
    double? turbulence,
    double? friction,
    double? gravity,
    double? wind,
    Map<String, dynamic>? algorithmSpecificParams,
    bool? animate,
    bool? interactionEnabled,
    double? speed,
    AlgorithmType? algorithmType,
  }) {
    return ParameterSet(
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorPalette: colorPalette ?? this.colorPalette,
      particleCount: particleCount ?? this.particleCount,
      particleShape: particleShape ?? this.particleShape,
      minParticleSize: minParticleSize ?? this.minParticleSize,
      maxParticleSize: maxParticleSize ?? this.maxParticleSize,
      interactionRadius: interactionRadius ?? this.interactionRadius,
      interactionStrength: interactionStrength ?? this.interactionStrength,
      enableCollisions: enableCollisions ?? this.enableCollisions,
      bounceFactor: bounceFactor ?? this.bounceFactor,
      movementBehavior: movementBehavior ?? this.movementBehavior,
      turbulence: turbulence ?? this.turbulence,
      friction: friction ?? this.friction,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      algorithmSpecificParams: algorithmSpecificParams ?? this.algorithmSpecificParams,
      animate: animate ?? this.animate,
      interactionEnabled: interactionEnabled ?? this.interactionEnabled,
      speed: speed ?? this.speed,
      algorithmType: algorithmType ?? this.algorithmType,
    );
  }
}