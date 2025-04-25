import 'dart:math';
import 'package:flutter/material.dart';
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';
import 'flow_field.dart';

class FlowFieldAlgorithm extends GenerativeAlgorithm {
  late FlowField _flowField;
  final Random _random = Random();
  double _noiseZ = 0;
  ParameterSet _currentParams;

  FlowFieldAlgorithm(ParameterSet parameters) : _currentParams = parameters, super(parameters) {
    _initialize();
  }

  void _initialize() {
    _flowField = FlowField(_currentParams);
    _noiseZ = _random.nextDouble() * 1000;
  }

  @override
  void update(Duration delta) {
    final dt = delta.inMilliseconds / 1000.0;
    
    if (_currentParams.algorithmSpecificParams['animateField'] == true) {
      _noiseZ += _currentParams.algorithmSpecificParams['fieldAnimationSpeed'] as double? ?? 0.1;
      _flowField.updateField(_noiseZ);
    }

    _flowField.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & _currentParams.canvasSize,
      Paint()..color = _currentParams.backgroundColor,
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
      _currentParams = newParameters;
      _initialize();
    }
  }
}