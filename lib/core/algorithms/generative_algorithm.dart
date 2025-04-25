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
  void reset();
  void updateParameters(ParameterSet newParameters);
}