import 'package:flutter/material.dart';
import 'package:myapp/core/models/parameter_set.dart';

/// Abstract base class for all generative algorithms
abstract class GenerativeAlgorithm {
  /// The parameter set for this algorithm
  final ParameterSet parameters;
  
  /// Creates a new generative algorithm with the given parameters
  GenerativeAlgorithm(this.parameters);
  
  /// Initialize the algorithm
  void initialize();
  
  /// Update the algorithm state
  void update(double deltaTime);
  
  /// Render the algorithm output
  void render(Canvas canvas, Size size) {
    // Default implementation does nothing
  }
  
  /// Called when parameters have been updated
  void onParametersUpdated();
}