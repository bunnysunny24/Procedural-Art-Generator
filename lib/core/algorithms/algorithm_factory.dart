import '../models/parameter_set.dart';
import 'generative_algorithm.dart';
import 'particle_system_algorithm.dart';
import 'flow_field_algorithm.dart';
import 'fractal_algorithm.dart';
import 'cellular_automata_algorithm.dart';
import 'voronoi_algorithm.dart';

/// Factory class to create appropriate algorithm instances based on parameters
class AlgorithmFactory {
  /// Create a generative algorithm based on parameter set
  static GenerativeAlgorithm createAlgorithm(
    AlgorithmType type,
    ParameterSet parameters,
  ) {
    switch (type) {
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
        throw UnimplementedError('Wave Function Collapse algorithm not yet implemented');
    }
  }
}