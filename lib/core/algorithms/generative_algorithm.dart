import 'dart:ui';

import 'package:flutter/material.dart';
import '../../models/art_parameters.dart';

/// Base class for all generative algorithms
abstract class GenerativeAlgorithm {
  /// The parameters for this algorithm
  final ArtParameters parameters;
  
  /// Constructor
  GenerativeAlgorithm(this.parameters);
  
  /// Initialize the algorithm
  void initialize();
  
  /// Update the algorithm with the given time delta
  void update(double deltaTime);
  
  /// Render the current state to the canvas
  void render(Canvas canvas);
  
  /// Handle user interaction at the given position
  void handleInteraction(Offset position, bool isActive);
  
  /// Called when parameters are updated
  void onParametersUpdated();
}