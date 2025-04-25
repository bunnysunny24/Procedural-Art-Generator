import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/parameter_set.dart';

/// Base class for all generative art algorithms
abstract class GenerativeAlgorithm {
  /// The current parameter set controlling the algorithm
  ParameterSet parameters;
  
  /// Creates a new generative algorithm with the provided parameters
  GenerativeAlgorithm(this.parameters);
  
  /// Updates the algorithm parameters
  void updateParameters(ParameterSet newParameters) {
    parameters = newParameters;
    onParametersUpdated();
  }
  
  /// Called when parameters are updated to allow algorithm-specific handling
  void onParametersUpdated() {
    // Override in subclasses to perform algorithm-specific parameter handling
  }
  
  /// Initialize the algorithm
  void initialize();
  
  /// Update the algorithm state for the next frame
  void update(double deltaTime);
  
  /// Render the current state to the canvas
  void render(Canvas canvas);
  
  /// Handle user interaction at the specified position
  void handleInteraction(Offset position, bool isActive);
  
  /// Reset the algorithm to initial state
  void reset() {
    initialize();
  }
  
  /// Clean up any resources when the algorithm is no longer needed
  void dispose() {
    // Override in subclasses if needed
  }
  
  /// Export the current state as an image
  Future<Image> exportAsImage() async {
    // Default implementation - override in subclasses if a more efficient
    // approach is available for a specific algorithm
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw background
    final backgroundPaint = Paint()..color = parameters.backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, parameters.canvasSize.width, parameters.canvasSize.height),
      backgroundPaint
    );
    
    // Render the current state
    render(canvas);
    
    // Convert to an image
    final picture = recorder.endRecording();
    return await picture.toImage(
      parameters.canvasSize.width.round(),
      parameters.canvasSize.height.round()
    );
  }
}