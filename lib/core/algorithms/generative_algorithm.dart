import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/parameter_set.dart';

/// Abstract base class for all generative algorithms in the application.
/// 
/// This class defines the common interface and functionality that all
/// specific algorithm implementations must provide.
abstract class GenerativeAlgorithm {
  /// The parameters controlling the algorithm's behavior
  ParameterSet parameters;
  
  /// Constructor that takes algorithm parameters
  GenerativeAlgorithm(this.parameters);
  
  /// Initialize the algorithm with current parameters
  void initialize();
  
  /// Update algorithm state for the next frame
  void update();
  
  /// Render the current state to the canvas
  void render(Canvas canvas, Size size);
  
  /// Handle user interaction
  void handleInteraction(Offset? position, bool isPressed);
  
  /// Reset the algorithm to initial state
  void reset();
  
  /// Update algorithm parameters
  void updateParameters(ParameterSet newParameters);
  
  /// Clean up resources
  void dispose();
}