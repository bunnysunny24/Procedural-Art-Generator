/// Defines how colors should be applied to elements
enum ColorMode {
  /// Single color for all elements
  single,
  
  /// Gradient based on position
  gradient,
  
  /// Color based on position
  position,
  
  /// Color based on velocity
  velocity,
  
  /// Color based on age
  age,
  
  /// Random color from palette
  random,
  
  /// Custom color assignment
  custom,
}