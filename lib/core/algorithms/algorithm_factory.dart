import 'dart:ui';

import '../models/parameter_set.dart';
import 'particle_system.dart';
import 'flow_field.dart';

/// Abstract base class for all art generation algorithms
abstract class GenerativeAlgorithm {
  /// Update the algorithm simulation
  void update();
  
  /// Render the current state to a canvas
  void render(Canvas canvas);
  
  /// Update the parameters used by the algorithm
  void updateParameters(ParameterSet params);
  
  /// Handle user interaction at the specified point
  void handleInteraction(Offset? point);
}

/// Factory for creating appropriate algorithm instances
class AlgorithmFactory {
  /// Create a new algorithm instance based on parameter set
  static GenerativeAlgorithm createAlgorithm(ParameterSet params) {
    switch (params.algorithmType) {
      case AlgorithmType.flowField:
        return _FlowFieldAdapter(params);
        
      case AlgorithmType.particleSystem:
      default:
        return _ParticleSystemAdapter(params);
    }
  }
}

/// Adapter to make ParticleSystemAlgorithm conform to GenerativeAlgorithm
class _ParticleSystemAdapter implements GenerativeAlgorithm {
  final ParticleSystemAlgorithm _algorithm;
  
  _ParticleSystemAdapter(ParameterSet params) : _algorithm = ParticleSystemAlgorithm(params);
  
  @override
  void update() => _algorithm.update();
  
  @override
  void render(Canvas canvas) => _algorithm.render(canvas);
  
  @override
  void updateParameters(ParameterSet params) => _algorithm.updateParameters(params);
  
  @override
  void handleInteraction(Offset? point) => _algorithm.handleInteraction(point);
}

/// Adapter to make FlowFieldAlgorithm conform to GenerativeAlgorithm
class _FlowFieldAdapter implements GenerativeAlgorithm {
  final FlowFieldAlgorithm _algorithm;
  
  _FlowFieldAdapter(ParameterSet params) : _algorithm = FlowFieldAlgorithm(params);
  
  @override
  void update() => _algorithm.update();
  
  @override
  void render(Canvas canvas) => _algorithm.render(canvas);
  
  @override
  void updateParameters(ParameterSet params) => _algorithm.updateParameters(params);
  
  @override
  void handleInteraction(Offset? point) => _algorithm.handleInteraction(point);
}