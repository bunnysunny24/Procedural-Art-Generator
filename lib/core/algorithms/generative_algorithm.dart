import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/parameter_set.dart';

/// Base abstract class for all generative art algorithms
abstract class GenerativeAlgorithm {
  /// Current parameter set for this algorithm
  ParameterSet parameters;
  
  /// Current interaction point for user interaction
  Offset? interactionPoint;
  
  /// Constructor that requires parameters
  GenerativeAlgorithm(this.parameters);
  
  /// Update the algorithm state for the next frame
  void update();
  
  /// Render the current state to a canvas
  void render(Canvas canvas);
  
  /// Handle user interaction with the canvas
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  /// Update the algorithm parameters
  void updateParameters(ParameterSet newParameters) {
    parameters = newParameters;
  }
  
  /// Reset the algorithm to its initial state
  void reset();
  
  /// Create a preview image of this algorithm
  Future<Image?> createPreview(Size size);
}