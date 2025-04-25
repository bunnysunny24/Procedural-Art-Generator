import 'dart:ui';
import '../algorithms/generative_algorithm.dart';

class ParameterSet {
  final AlgorithmType algorithmType;
  final bool interactionEnabled;
  final Color primaryColor;
  final Color secondaryColor;
  final double speed;
  final double scale;
  final int count;

  ParameterSet({
    this.algorithmType = AlgorithmType.particleSystem,
    this.interactionEnabled = true,
    this.primaryColor = const Color(0xFF4A90E2),
    this.secondaryColor = const Color(0xFF50E3C2),
    this.speed = 1.0,
    this.scale = 1.0,
    this.count = 100,
  });

  ParameterSet copyWith({
    AlgorithmType? algorithmType,
    bool? interactionEnabled,
    Color? primaryColor,
    Color? secondaryColor,
    double? speed,
    double? scale,
    int? count,
  }) {
    return ParameterSet(
      algorithmType: algorithmType ?? this.algorithmType,
      interactionEnabled: interactionEnabled ?? this.interactionEnabled,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      speed: speed ?? this.speed,
      scale: scale ?? this.scale,
      count: count ?? this.count,
    );
  }
}