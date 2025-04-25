import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../models/parameter_set.dart';

/// Base class for all art generation algorithms
abstract class BaseAlgorithm {
  /// The current parameter set for the algorithm
  ParameterSet get parameters;
  
  /// Set the parameter set
  set parameters(ParameterSet value);
  
  /// Initialize the algorithm with a parameter set
  void initialize(ParameterSet params);
  
  /// Update the algorithm state for the current frame
  void update(Duration elapsedTime);
  
  /// Render the current state to a canvas
  void render(Canvas canvas, Size size);
  
  /// Handle user interaction
  void handlePointerEvent(Offset position, PointerEventType eventType);
  
  /// Reset the algorithm state
  void reset();
  
  /// Clean up resources
  void dispose();
  
  /// Export the current state as an image
  Future<ui.Image> exportAsImage(Size size);
  
  /// Get a description of the algorithm
  String get description;
  
  /// Get the name of the algorithm
  String get name;
  
  /// Whether the algorithm can be resized
  bool get canResize;
  
  /// Whether the algorithm supports user interaction
  bool get supportsInteraction;
  
  /// Whether the algorithm can export its state
  bool get canExport;
}

/// Type of pointer event
enum PointerEventType {
  down,
  move,
  up,
  hover,
}

/// Exception class for algorithm-related errors
class AlgorithmException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  
  AlgorithmException(this.message, [this.stackTrace]);
  
  @override
  String toString() => 'AlgorithmException: $message';
}