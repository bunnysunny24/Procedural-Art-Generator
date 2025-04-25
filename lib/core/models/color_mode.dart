/// Defines how colors are assigned in the art generation process
enum ColorMode {
  /// Colors are assigned randomly from the palette
  random,
  
  /// Colors are assigned based on position
  position,
  
  /// Colors are assigned based on time/animation progress
  time,
  
  /// Colors are assigned based on flow field values
  flow
}