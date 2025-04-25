/// The mode for determining colors in the art generation
enum ColorMode {
  /// Colors are selected randomly from the palette
  random,
  
  /// Colors are determined by position (using a gradient or mapping technique)
  position,
  
  /// Colors are determined by velocity
  velocity,
  
  /// Colors are determined by the flow field angle
  flowField,
}