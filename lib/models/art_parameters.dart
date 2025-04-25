import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ParticleType { circle, square, triangle, line, custom }
enum AnimationType { flow, explode, swirl, bounce, random }
enum ColorMode { single, gradient, rainbow, custom }

class ArtParameters {
  String id;
  String name;
  
  // Canvas parameters
  Size canvasSize;
  Color backgroundColor;
  
  // Particle parameters
  ParticleType particleType;
  int particleCount;
  double minParticleSize;
  double maxParticleSize;
  
  // Animation parameters
  AnimationType animationType;
  double speed;
  double friction;
  double turbulence;
  
  // Color parameters
  ColorMode colorMode;
  Color primaryColor;
  Color secondaryColor;
  List<Color> customColors;
  
  // Physics parameters
  double gravity;
  double wind;
  bool collisionEnabled;
  
  // Interaction parameters
  bool gestureEnabled;
  double interactionStrength;

  ArtParameters({
    String? id,
    this.name = 'Untitled Art',
    this.canvasSize = const Size(800, 600),
    this.backgroundColor = Colors.black,
    this.particleType = ParticleType.circle,
    this.particleCount = 500,
    this.minParticleSize = 2.0,
    this.maxParticleSize = 10.0,
    this.animationType = AnimationType.flow,
    this.speed = 1.0,
    this.friction = 0.02,
    this.turbulence = 0.5,
    this.colorMode = ColorMode.gradient,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.purple,
    List<Color>? customColors,
    this.gravity = 0.05,
    this.wind = 0.0,
    this.collisionEnabled = false,
    this.gestureEnabled = true,
    this.interactionStrength = 1.0,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.customColors = customColors ?? [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];

  // Create a copy with updated parameters
  ArtParameters copyWith({
    String? id,
    String? name,
    Size? canvasSize,
    Color? backgroundColor,
    ParticleType? particleType,
    int? particleCount,
    double? minParticleSize,
    double? maxParticleSize,
    AnimationType? animationType,
    double? speed,
    double? friction,
    double? turbulence,
    ColorMode? colorMode,
    Color? primaryColor,
    Color? secondaryColor,
    List<Color>? customColors,
    double? gravity,
    double? wind,
    bool? collisionEnabled,
    bool? gestureEnabled,
    double? interactionStrength,
  }) {
    return ArtParameters(
      id: id ?? this.id,
      name: name ?? this.name,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      particleType: particleType ?? this.particleType,
      particleCount: particleCount ?? this.particleCount,
      minParticleSize: minParticleSize ?? this.minParticleSize,
      maxParticleSize: maxParticleSize ?? this.maxParticleSize,
      animationType: animationType ?? this.animationType,
      speed: speed ?? this.speed,
      friction: friction ?? this.friction,
      turbulence: turbulence ?? this.turbulence,
      colorMode: colorMode ?? this.colorMode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      customColors: customColors ?? this.customColors,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      collisionEnabled: collisionEnabled ?? this.collisionEnabled,
      gestureEnabled: gestureEnabled ?? this.gestureEnabled,
      interactionStrength: interactionStrength ?? this.interactionStrength,
    );
  }
  
  // Convert to and from JSON for saving and loading
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'backgroundColor': backgroundColor.value,
      'particleType': particleType.index,
      'particleCount': particleCount,
      'minParticleSize': minParticleSize,
      'maxParticleSize': maxParticleSize,
      'animationType': animationType.index,
      'speed': speed,
      'friction': friction,
      'turbulence': turbulence,
      'colorMode': colorMode.index,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'customColors': customColors.map((c) => c.value).toList(),
      'gravity': gravity,
      'wind': wind,
      'collisionEnabled': collisionEnabled,
      'gestureEnabled': gestureEnabled,
      'interactionStrength': interactionStrength,
    };
  }
  
  factory ArtParameters.fromJson(Map<String, dynamic> json) {
    return ArtParameters(
      id: json['id'],
      name: json['name'],
      canvasSize: Size(json['canvasWidth'], json['canvasHeight']),
      backgroundColor: Color(json['backgroundColor']),
      particleType: ParticleType.values[json['particleType']],
      particleCount: json['particleCount'],
      minParticleSize: json['minParticleSize'],
      maxParticleSize: json['maxParticleSize'],
      animationType: AnimationType.values[json['animationType']],
      speed: json['speed'],
      friction: json['friction'],
      turbulence: json['turbulence'],
      colorMode: ColorMode.values[json['colorMode']],
      primaryColor: Color(json['primaryColor']),
      secondaryColor: Color(json['secondaryColor']),
      customColors: (json['customColors'] as List).map((c) => Color(c as int)).toList(),
      gravity: json['gravity'],
      wind: json['wind'],
      collisionEnabled: json['collisionEnabled'],
      gestureEnabled: json['gestureEnabled'],
      interactionStrength: json['interactionStrength'],
    );
  }
}