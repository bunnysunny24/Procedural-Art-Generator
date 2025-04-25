import 'dart:ui';

import '../models/parameter_set.dart';
import 'generative_algorithm.dart';
import 'particle_system_algorithm.dart';
import 'flow_field_algorithm.dart';
import 'fractal_algorithm.dart';
import 'cellular_automata_algorithm.dart';
import 'voronoi_algorithm.dart';
import 'wave_function_collapse_algorithm.dart';

/// Factory class to create appropriate algorithm instances based on parameters
class AlgorithmFactory {
  /// Create a generative algorithm based on parameter set
  static GenerativeAlgorithm createAlgorithm(ParameterSet parameters) {
    switch (parameters.algorithmType) {
      case AlgorithmType.particleSystem:
        return ParticleSystemAlgorithm(parameters);
        
      case AlgorithmType.flowField:
        return FlowFieldAlgorithm(parameters);
        
      case AlgorithmType.fractal:
        return FractalAlgorithm(parameters);
        
      case AlgorithmType.cellularAutomata:
        return CellularAutomataAlgorithm(parameters);
      
      case AlgorithmType.voronoi:
        return VoronoiAlgorithm(parameters);
        
      case AlgorithmType.waveFunctionCollapse:
        return WaveFunctionCollapseAlgorithm(parameters);
        
      default:
        // Default to particle system if unknown
        return ParticleSystemAlgorithm(parameters);
    }
  }
}