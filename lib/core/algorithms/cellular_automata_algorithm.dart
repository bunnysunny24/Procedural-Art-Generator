import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'generative_algorithm.dart';
import '../models/parameter_set.dart';

/// Implementation of cellular automata algorithms (e.g., Game of Life)
class CellularAutomataAlgorithm extends GenerativeAlgorithm {
  /// Current grid state
  late List<List<int>> _grid;
  
  /// Next grid state (for calculations)
  late List<List<int>> _nextGrid;
  
  /// Grid dimensions
  late int _rows;
  late int _cols;
  
  /// Cell size
  late double _cellSize;
  
  /// Random generator
  final Random _random = Random();
  
  /// Update timer to control simulation speed
  int _updateCounter = 0;
  
  CellularAutomataAlgorithm(super.parameters) {
    _initialize();
  }
  
  void _initialize() {
    // Calculate grid dimensions based on cell size
    _cellSize = parameters.algorithmSpecificParams['cellSize'] as double? ?? 10.0;
    _rows = (parameters.canvasSize.height / _cellSize).ceil();
    _cols = (parameters.canvasSize.width / _cellSize).ceil();
    
    // Initialize grids
    _grid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => 0),
    );
    
    _nextGrid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => 0),
    );
    
    // Set up initial pattern
    _setupInitialPattern();
  }
  
  void _setupInitialPattern() {
    final patternType = parameters.algorithmSpecificParams['patternType'] as String? ?? 'random';
    
    switch (patternType) {
      case 'random':
        _setupRandomPattern();
        break;
      case 'glider':
        _setupGliderPattern();
        break;
      case 'blinker':
        _setupBlinkerPattern();
        break;
      default:
        _setupRandomPattern();
        break;
    }
  }
  
  void _setupRandomPattern() {
    final fillRatio = parameters.algorithmSpecificParams['fillRatio'] as double? ?? 0.3;
    
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        _grid[y][x] = _random.nextDouble() < fillRatio ? 1 : 0;
      }
    }
  }
  
  void _setupGliderPattern() {
    // Clear grid
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        _grid[y][x] = 0;
      }
    }
    
    // Add a glider pattern at the center
    final centerX = _cols ~/ 2;
    final centerY = _rows ~/ 2;
    
    _grid[centerY - 1][centerX] = 1;
    _grid[centerY][centerX + 1] = 1;
    _grid[centerY + 1][centerX - 1] = 1;
    _grid[centerY + 1][centerX] = 1;
    _grid[centerY + 1][centerX + 1] = 1;
  }
  
  void _setupBlinkerPattern() {
    // Clear grid
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        _grid[y][x] = 0;
      }
    }
    
    // Add a blinker pattern at the center
    final centerX = _cols ~/ 2;
    final centerY = _rows ~/ 2;
    
    _grid[centerY - 1][centerX] = 1;
    _grid[centerY][centerX] = 1;
    _grid[centerY + 1][centerX] = 1;
  }
  
  @override
  void update() {
    // Control update speed
    final updateRate = parameters.algorithmSpecificParams['updateRate'] as int? ?? 5;
    _updateCounter++;
    
    if (_updateCounter < updateRate) {
      return;
    }
    
    _updateCounter = 0;
    
    // Apply Game of Life rules
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final neighbors = _countNeighbors(x, y);
        final currentState = _grid[y][x];
        
        // Apply Conway's Game of Life rules
        if (currentState == 1 && (neighbors < 2 || neighbors > 3)) {
          // Cell dies
          _nextGrid[y][x] = 0;
        } else if (currentState == 0 && neighbors == 3) {
          // Cell becomes alive
          _nextGrid[y][x] = 1;
        } else {
          // State remains the same
          _nextGrid[y][x] = currentState;
        }
      }
    }
    
    // Swap grids
    final temp = _grid;
    _grid = _nextGrid;
    _nextGrid = temp;
    
    // Handle interaction if enabled
    if (parameters.interactionEnabled && interactionPoint != null) {
      _handleInteraction();
    }
  }
  
  int _countNeighbors(int x, int y) {
    int count = 0;
    
    // Check all 8 surrounding cells
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue; // Skip self
        
        // Get neighbor coordinates with wraparound
        final nx = (x + dx + _cols) % _cols;
        final ny = (y + dy + _rows) % _rows;
        
        // Count live neighbors
        if (_grid[ny][nx] == 1) {
          count++;
        }
      }
    }
    
    return count;
  }
  
  void _handleInteraction() {
    if (interactionPoint == null) return;
    
    // Convert interaction point to grid coordinates
    final gridX = (interactionPoint!.dx / _cellSize).floor();
    final gridY = (interactionPoint!.dy / _cellSize).floor();
    
    // Ensure coordinates are in bounds
    if (gridX >= 0 && gridY >= 0 && gridX < _cols && gridY < _rows) {
      // Set cells around interaction point to alive
      final radius = parameters.interactionRadius ~/ _cellSize;
      
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final nx = (gridX + dx + _cols) % _cols;
          final ny = (gridY + dy + _rows) % _rows;
          
          // Make cells alive with higher probability at center
          final dist = sqrt(dx * dx + dy * dy);
          if (dist <= radius && _random.nextDouble() > dist / radius) {
            _grid[ny][nx] = 1;
          }
        }
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, parameters.canvasSize.width, parameters.canvasSize.height),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Get cell colors
    final aliveColor = parameters.colorPalette.colors.isNotEmpty ? 
        parameters.colorPalette.colors.first : Colors.white;
    final deadColor = parameters.algorithmSpecificParams['showDeadCells'] == true ? 
        Colors.grey.withOpacity(0.2) : Colors.transparent;
    
    // Draw cells
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final cellState = _grid[y][x];
        
        // Skip drawing dead cells if not showing them
        if (cellState == 0 && parameters.algorithmSpecificParams['showDeadCells'] != true) {
          continue;
        }
        
        final rect = Rect.fromLTWH(
          x * _cellSize, 
          y * _cellSize, 
          _cellSize, 
          _cellSize,
        );
        
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = cellState == 1 ? aliveColor : deadColor;
          
        canvas.drawRect(rect, paint);
      }
    }
    
    // Draw grid lines if enabled
    if (parameters.algorithmSpecificParams['showGrid'] == true) {
      _drawGridLines(canvas);
    }
    
    // Draw interaction indicator
    if (parameters.interactionEnabled && interactionPoint != null) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      canvas.drawCircle(
        interactionPoint!,
        parameters.interactionRadius,
        paint,
      );
    }
  }
  
  void _drawGridLines(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
      
    // Draw horizontal lines
    for (int y = 0; y <= _rows; y++) {
      canvas.drawLine(
        Offset(0, y * _cellSize),
        Offset(_cols * _cellSize, y * _cellSize),
        paint,
      );
    }
    
    // Draw vertical lines
    for (int x = 0; x <= _cols; x++) {
      canvas.drawLine(
        Offset(x * _cellSize, 0),
        Offset(x * _cellSize, _rows * _cellSize),
        paint,
      );
    }
  }
  
  @override
  void reset() {
    _initialize();
  }
  
  @override
  void updateParameters(ParameterSet newParameters) {
    final oldParams = parameters;
    parameters = newParameters;
    
    // Reinitialize if essential parameters changed
    if (oldParams.canvasSize != newParameters.canvasSize || 
        oldParams.algorithmSpecificParams['cellSize'] != newParameters.algorithmSpecificParams['cellSize']) {
      _initialize();
    }
  }
  
  @override
  void handleInteraction(Offset? point) {
    interactionPoint = point;
  }
  
  @override
  Future<ui.Image?> createPreview(Size size) async {
    // Implementation will depend on how you plan to use previews
    return null;
  }
}