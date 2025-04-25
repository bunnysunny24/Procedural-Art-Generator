import 'dart:ui';
import '../models/parameter_set.dart';

enum AlgorithmType {
  particleSystem,
  flowField,
  fractal,
  cellularAutomata,
  voronoi,
  waveFunctionCollapse,
}

abstract class GenerativeAlgorithm {
  final ParameterSet parameters;

  GenerativeAlgorithm(this.parameters);

  void update(Duration delta);
  void render(Canvas canvas);
  void handleInput(Offset position, bool isActive);
  
  // Optional cleanup method for resources
  void dispose() {}
}