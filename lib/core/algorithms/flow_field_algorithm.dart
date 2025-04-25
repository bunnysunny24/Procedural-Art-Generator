import 'dart:math';
import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';
import 'flow_field.dart';

class FlowFieldAlgorithm extends GenerativeAlgorithm {
  late FlowField _flowField;
  final Random _random = Random();
  double _noiseZ = 0;

  FlowFieldAlgorithm(ParameterSet parameters) : super(parameters) {
    _initialize();
  }

  void _initialize() {
    _flowField = FlowField(parameters);
    _noiseZ = _random.nextDouble() * 1000;
  }

  @override
  void update(Duration delta) {
    final dt = delta.inMilliseconds / 1000.0;
    
    if (parameters.algorithmSpecificParams['animateField'] == true) {
      _noiseZ += parameters.algorithmSpecificParams['fieldAnimationSpeed'] as double? ?? 0.1;
      _flowField.updateField(_noiseZ);
    }

    _flowField.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & parameters.canvasSize,
      Paint()..color = parameters.backgroundColor,
    );

    _flowField.render(canvas);
  }

  @override
  void handleInput(Offset position, bool isActive) {
    if (!isActive) return;
    _flowField.addDisturbance(position);
  }

  @override
  void reset() {
    _initialize();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    final needsReset = _flowField.needsReset(newParameters);
    
    if (needsReset) {
      parameters = newParameters;
      _initialize();
    }
  }
}