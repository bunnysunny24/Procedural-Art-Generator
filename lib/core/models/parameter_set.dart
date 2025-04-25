import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'color_palette.dart';

/// Represents a complete set of parameters for controlling art generation
class ParameterSet extends Equatable {
  /// Name of this parameter set
  final String name;
  
  /// The selected algorithm type
  final String algorithmType;
  
  /// The color palette for the art
  final ColorPalette colorPalette;
  
  /// Resolution or detail level (higher = more detail)
  final double resolution;
  
  /// Speed of animation
  final double speed;
  
  /// Random seed for reproducible generation
  final int seed;
  
  /// Whether to use randomness in the generation
  final bool useRandomness;
  
  /// Noise scale for algorithms using noise functions
  final double noiseScale;
  
  /// Flow field strength (for flow field algorithms)
  final double flowStrength;
  
  /// Number of particles or elements
  final int elementCount;
  
  /// Element size range (min and max)
  final RangeValues elementSizeRange;
  
  /// Element lifetime in seconds (if applicable)
  final double elementLifetime;
  
  /// Additional algorithm-specific parameters
  final Map<String, dynamic> additionalParams;
  
  /// Timestamp for when this parameter set was created
  final DateTime createdAt;
  
  /// Timestamp for when this parameter set was last modified
  final DateTime modifiedAt;
  
  const ParameterSet({
    required this.name,
    required this.algorithmType,
    required this.colorPalette,
    required this.resolution,
    required this.speed,
    required this.seed,
    required this.useRandomness,
    required this.noiseScale,
    required this.flowStrength,
    required this.elementCount,
    required this.elementSizeRange,
    required this.elementLifetime,
    required this.additionalParams,
    required this.createdAt,
    required this.modifiedAt,
  });
  
  /// Default parameter set with common values
  factory ParameterSet.defaultSet() {
    return ParameterSet(
      name: 'Default',
      algorithmType: 'particle',
      colorPalette: ColorPalette.defaultPalette(),
      resolution: 1.0,
      speed: 1.0,
      seed: 42,
      useRandomness: true,
      noiseScale: 0.01,
      flowStrength: 0.5,
      elementCount: 1000,
      elementSizeRange: const RangeValues(2.0, 6.0),
      elementLifetime: 5.0,
      additionalParams: {},
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  }
  
  /// Create a random parameter set
  factory ParameterSet.random() {
    final random = Random();
    final algorithms = ['particle', 'flowfield', 'cellular', 'diffusion', 'voronoi'];
    
    return ParameterSet(
      name: 'Random ${DateTime.now().millisecondsSinceEpoch}',
      algorithmType: algorithms[random.nextInt(algorithms.length)],
      colorPalette: ColorPalette.random(),
      resolution: 0.5 + random.nextDouble() * 1.5, // 0.5 to 2.0
      speed: 0.2 + random.nextDouble() * 1.8, // 0.2 to 2.0
      seed: random.nextInt(10000),
      useRandomness: random.nextBool(),
      noiseScale: 0.001 + random.nextDouble() * 0.049, // 0.001 to 0.05
      flowStrength: 0.1 + random.nextDouble() * 0.9, // 0.1 to 1.0
      elementCount: 100 + random.nextInt(5000), // 100 to 5100
      elementSizeRange: RangeValues(
        1.0 + random.nextDouble() * 4.0, // min: 1.0 to 5.0
        5.0 + random.nextDouble() * 25.0, // max: 5.0 to 30.0
      ),
      elementLifetime: 1.0 + random.nextDouble() * 9.0, // 1.0 to 10.0
      additionalParams: {
        'turbulence': random.nextDouble(),
        'complexity': 0.2 + random.nextDouble() * 0.8,
        'symmetry': random.nextDouble(),
        'fadeType': random.nextInt(4),
      },
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  }
  
  /// Create a copy with modified properties
  ParameterSet copyWith({
    String? name,
    String? algorithmType,
    ColorPalette? colorPalette,
    double? resolution,
    double? speed,
    int? seed,
    bool? useRandomness,
    double? noiseScale,
    double? flowStrength,
    int? elementCount,
    RangeValues? elementSizeRange,
    double? elementLifetime,
    Map<String, dynamic>? additionalParams,
    DateTime? modifiedAt,
  }) {
    return ParameterSet(
      name: name ?? this.name,
      algorithmType: algorithmType ?? this.algorithmType,
      colorPalette: colorPalette ?? this.colorPalette,
      resolution: resolution ?? this.resolution,
      speed: speed ?? this.speed,
      seed: seed ?? this.seed,
      useRandomness: useRandomness ?? this.useRandomness,
      noiseScale: noiseScale ?? this.noiseScale,
      flowStrength: flowStrength ?? this.flowStrength,
      elementCount: elementCount ?? this.elementCount,
      elementSizeRange: elementSizeRange ?? this.elementSizeRange,
      elementLifetime: elementLifetime ?? this.elementLifetime,
      additionalParams: additionalParams ?? Map<String, dynamic>.from(this.additionalParams),
      createdAt: this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'algorithmType': algorithmType,
      'colorPalette': colorPalette.toJson(),
      'resolution': resolution,
      'speed': speed,
      'seed': seed,
      'useRandomness': useRandomness,
      'noiseScale': noiseScale,
      'flowStrength': flowStrength,
      'elementCount': elementCount,
      'elementSizeMin': elementSizeRange.start,
      'elementSizeMax': elementSizeRange.end,
      'elementLifetime': elementLifetime,
      'additionalParams': additionalParams,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
  
  /// Create from JSON map
  factory ParameterSet.fromJson(Map<String, dynamic> json) {
    return ParameterSet(
      name: json['name'] as String? ?? 'Imported',
      algorithmType: json['algorithmType'] as String? ?? 'particle',
      colorPalette: json['colorPalette'] != null 
          ? ColorPalette.fromJson(json['colorPalette'] as Map<String, dynamic>)
          : ColorPalette.defaultPalette(),
      resolution: (json['resolution'] as num?)?.toDouble() ?? 1.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      seed: json['seed'] as int? ?? 42,
      useRandomness: json['useRandomness'] as bool? ?? true,
      noiseScale: (json['noiseScale'] as num?)?.toDouble() ?? 0.01,
      flowStrength: (json['flowStrength'] as num?)?.toDouble() ?? 0.5,
      elementCount: json['elementCount'] as int? ?? 1000,
      elementSizeRange: RangeValues(
        (json['elementSizeMin'] as num?)?.toDouble() ?? 2.0,
        (json['elementSizeMax'] as num?)?.toDouble() ?? 6.0,
      ),
      elementLifetime: (json['elementLifetime'] as num?)?.toDouble() ?? 5.0,
      additionalParams: (json['additionalParams'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null 
          ? DateTime.parse(json['modifiedAt'] as String) 
          : DateTime.now(),
    );
  }
  
  /// Export as JSON string
  String exportToJson() {
    return jsonEncode(toJson());
  }
  
  /// Create from JSON string
  factory ParameterSet.importFromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ParameterSet.fromJson(json);
  }
  
  @override
  List<Object?> get props => [
    name,
    algorithmType,
    colorPalette,
    resolution,
    speed,
    seed,
    useRandomness,
    noiseScale,
    flowStrength,
    elementCount,
    elementSizeRange,
    elementLifetime,
    additionalParams,
    createdAt,
    modifiedAt,
  ];
}