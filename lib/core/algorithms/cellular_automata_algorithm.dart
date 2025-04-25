import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/parameter_set.dart';
import '../models/color_palette.dart';
import 'generative_algorithm.dart';

/// Implementation of cellular automata-based generative algorithm
class CellularAutomataAlgorithm extends GenerativeAlgorithm {
  /// Types of cellular automata rules
  enum AutomataType {
    gameOfLife,   // Conway's Game of Life
    briansBrain,  // Brian's Brain
    seeds,        // Seeds
    wireworld,    // Wireworld
    elementary,   // Elementary cellular automaton (1D)
    custom        // Custom rule set
  }
  
  /// Current automata type
  late AutomataType _automataType;
  
  /// Grid cell size in pixels
  late double _cellSize;
  
  /// Grid dimensions
  late int _columns;
  late int _rows;
  
  /// Current and next grid states
  late List<List<int>> _grid;
  late List<List<int>> _nextGrid;
  
  /// Random number generator
  final Random _random = Random();
  
  /// Elementary automata rule number (for elementary type)
  late int _elementaryRule;
  
  /// Custom rule settings for survival and birth
  late List<int> _survivalRules;
  late List<int> _birthRules;
  
  /// Generation counter
  int _generation = 0;
  
  /// Current interaction point
  Offset? _interactionPoint;
  
  /// Whether interaction is currently active
  bool _interactionActive = false;
  
  /// State colors (specific to automata type)
  late List<Color> _stateColors;

  CellularAutomataAlgorithm(super.parameters) {
    initialize();
  }

  @override
  void initialize() {
    _initializeParameters();
    _initializeGrid();
    _initializeColors();
    _generation = 0;
  }
  
  /// Initialize algorithm parameters from parameters
  void _initializeParameters() {
    final specificParams = parameters.algorithmSpecificParams;
    
    // Get automata type
    final typeIndex = specificParams['automataType'] as int? ?? 0;
    _automataType = AutomataType.values[typeIndex.clamp(0, AutomataType.values.length - 1)];
    
    // Get cell size
    _cellSize = specificParams['cellSize'] as double? ?? 10.0;
    
    // Calculate grid dimensions based on cell size
    _columns = (parameters.canvasSize.width / _cellSize).ceil();
    _rows = (parameters.canvasSize.height / _cellSize).ceil();
    
    // Elementary rule number (0-255)
    _elementaryRule = specificParams['elementaryRule'] as int? ?? 30;
    
    // Custom rules for Game of Life-like automata
    _survivalRules = specificParams['survivalRules'] as List<int>? ?? [2, 3];
    _birthRules = specificParams['birthRules'] as List<int>? ?? [3];
  }
  
  /// Initialize the grid with a starting pattern
  void _initializeGrid() {
    // Create grids
    _grid = List.generate(
      _columns, 
      (_) => List.generate(_rows, (_) => 0),
    );
    
    _nextGrid = List.generate(
      _columns, 
      (_) => List.generate(_rows, (_) => 0),
    );
    
    // Initialize with a pattern based on the automata type
    switch (_automataType) {
      case AutomataType.gameOfLife:
      case AutomataType.seeds:
      case AutomataType.custom:
        _initializeRandomPattern();
        break;
        
      case AutomataType.briansBrain:
        _initializeRandomPattern(stateCount: 3);
        break;
        
      case AutomataType.wireworld:
        _initializeWireworldPattern();
        break;
        
      case AutomataType.elementary:
        _initializeElementaryPattern();
        break;
    }
  }
  
  /// Initialize state colors based on automata type and color palette
  void _initializeColors() {
    final colorPalette = parameters.colorPalette;
    final colors = colorPalette.colors;
    
    switch (_automataType) {
      case AutomataType.gameOfLife:
      case AutomataType.seeds:
      case AutomataType.custom:
        // 2 states: dead and alive
        _stateColors = [
          parameters.backgroundColor,
          colors.isNotEmpty ? colors[0] : Colors.white,
        ];
        break;
        
      case AutomataType.briansBrain:
        // 3 states: dead, alive, dying
        _stateColors = [
          parameters.backgroundColor,
          colors.isNotEmpty ? colors[0] : Colors.white,
          colors.length > 1 ? colors[1].withOpacity(0.5) : Colors.grey,
        ];
        break;
        
      case AutomataType.wireworld:
        // 4 states: empty, electron head, electron tail, conductor
        _stateColors = [
          parameters.backgroundColor,
          colors.length > 0 ? colors[0] : Colors.blue,
          colors.length > 1 ? colors[1] : Colors.red,
          colors.length > 2 ? colors[2] : Colors.yellow,
        ];
        break;
        
      case AutomataType.elementary:
        // 2 states: off and on
        _stateColors = [
          parameters.backgroundColor,
          colors.isNotEmpty ? colors[0] : Colors.white,
        ];
        break;
    }
  }
  
  /// Initialize with a random pattern
  void _initializeRandomPattern({int stateCount = 2}) {
    final density = parameters.algorithmSpecificParams['initialDensity'] as double? ?? 0.3;
    
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        if (_random.nextDouble() < density) {
          _grid[x][y] = _random.nextInt(stateCount);
        } else {
          _grid[x][y] = 0;
        }
      }
    }
  }
  
  /// Initialize a pattern for Wireworld
  void _initializeWireworldPattern() {
    // Start with all empty
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        _grid[x][y] = 0;
      }
    }
    
    // Create conductor paths (state 3)
    final centerX = _columns ~/ 2;
    final centerY = _rows ~/ 2;
    final radius = min(_columns, _rows) ~/ 4;
    
    // Create a conductive loop
    for (int angle = 0; angle < 360; angle += 1) {
      final radians = angle * pi / 180;
      final x = centerX + (radius * cos(radians)).toInt();
      final y = centerY + (radius * sin(radians)).toInt();
      
      if (x >= 0 && x < _columns && y >= 0 && y < _rows) {
        _grid[x][y] = 3; // Conductor state
      }
    }
    
    // Add some electron heads (state 1) at random positions on the loop
    for (int i = 0; i < 3; i++) {
      final angle = _random.nextInt(360);
      final radians = angle * pi / 180;
      final x = centerX + (radius * cos(radians)).toInt();
      final y = centerY + (radius * sin(radians)).toInt();
      
      if (x >= 0 && x < _columns && y >= 0 && y < _rows) {
        _grid[x][y] = 1; // Electron head state
      }
    }
  }
  
  /// Initialize a pattern for Elementary cellular automata
  void _initializeElementaryPattern() {
    // Clear grid
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        _grid[x][y] = 0;
      }
    }
    
    // For elementary CA, we just need a single cell in the top row
    _grid[_columns ~/ 2][0] = 1;
  }

  @override
  void update() {
    switch (_automataType) {
      case AutomataType.gameOfLife:
      case AutomataType.custom:
        _updateGameOfLife();
        break;
        
      case AutomataType.briansBrain:
        _updateBriansBrain();
        break;
        
      case AutomataType.seeds:
        _updateSeeds();
        break;
        
      case AutomataType.wireworld:
        _updateWireworld();
        break;
        
      case AutomataType.elementary:
        _updateElementary();
        break;
    }
    
    // Handle interaction to add cells
    if (_interactionActive && _interactionPoint != null && parameters.interactionEnabled) {
      _handleInteractionEffects();
    }
    
    // Swap grids and increment generation
    final temp = _grid;
    _grid = _nextGrid;
    _nextGrid = temp;
    _generation++;
    
    // Possibly reset or modify after certain number of generations
    if (parameters.algorithmSpecificParams['autoReset'] == true && 
        _generation > (parameters.algorithmSpecificParams['resetGenerations'] ?? 100)) {
      initialize();
    }
  }
  
  /// Update for Conway's Game of Life and custom rules
  void _updateGameOfLife() {
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        final aliveNeighbors = _countAliveNeighbors(x, y);
        final currentState = _grid[x][y];
        
        if (currentState == 1) {
          // Cell is alive
          if (_survivalRules.contains(aliveNeighbors)) {
            _nextGrid[x][y] = 1; // Survival
          } else {
            _nextGrid[x][y] = 0; // Death
          }
        } else {
          // Cell is dead
          if (_birthRules.contains(aliveNeighbors)) {
            _nextGrid[x][y] = 1; // Birth
          } else {
            _nextGrid[x][y] = 0; // Stay dead
          }
        }
      }
    }
  }
  
  /// Update for Brian's Brain
  void _updateBriansBrain() {
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        final currentState = _grid[x][y];
        
        switch (currentState) {
          case 0: // Dead
            final aliveNeighbors = _countSpecificStateNeighbors(x, y, 1);
            if (aliveNeighbors == 2) {
              _nextGrid[x][y] = 1; // Birth
            } else {
              _nextGrid[x][y] = 0; // Stay dead
            }
            break;
            
          case 1: // Alive
            _nextGrid[x][y] = 2; // Always become dying
            break;
            
          case 2: // Dying
            _nextGrid[x][y] = 0; // Always become dead
            break;
        }
      }
    }
  }
  
  /// Update for Seeds
  void _updateSeeds() {
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        final aliveNeighbors = _countAliveNeighbors(x, y);
        final currentState = _grid[x][y];
        
        if (currentState == 0 && aliveNeighbors == 2) {
          _nextGrid[x][y] = 1; // Birth
        } else {
          _nextGrid[x][y] = 0; // Otherwise always dead
        }
      }
    }
  }
  
  /// Update for Wireworld
  void _updateWireworld() {
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        switch (_grid[x][y]) {
          case 0: // Empty
            _nextGrid[x][y] = 0; // Stays empty
            break;
            
          case 1: // Electron head
            _nextGrid[x][y] = 2; // Becomes electron tail
            break;
            
          case 2: // Electron tail
            _nextGrid[x][y] = 3; // Becomes conductor
            break;
            
          case 3: // Conductor
            final headNeighbors = _countSpecificStateNeighbors(x, y, 1);
            if (headNeighbors == 1 || headNeighbors == 2) {
              _nextGrid[x][y] = 1; // Becomes electron head
            } else {
              _nextGrid[x][y] = 3; // Remains conductor
            }
            break;
        }
      }
    }
  }
  
  /// Update for Elementary cellular automaton
  void _updateElementary() {
    // Elementary CA is 1D, so we only update a row at a time and shift down
    
    // First, shift everything down (losing the bottom row)
    for (int y = _rows - 1; y > 0; y--) {
      for (int x = 0; x < _columns; x++) {
        _nextGrid[x][y] = _grid[x][y - 1];
      }
    }
    
    // Then compute the new top row based on the current second row
    for (int x = 0; x < _columns; x++) {
      final left = (x > 0) ? _grid[x - 1][1] : _grid[_columns - 1][1];
      final center = _grid[x][1];
      final right = (x < _columns - 1) ? _grid[x + 1][1] : _grid[0][1];
      
      // Calculate the rule pattern
      final pattern = (left << 2) | (center << 1) | right;
      
      // Apply the elementary rule
      _nextGrid[x][0] = (_elementaryRule >> pattern) & 1;
    }
  }
  
  /// Count alive neighbors for Game of Life style rules
  int _countAliveNeighbors(int x, int y) {
    int count = 0;
    
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip self
        
        int nx = (x + dx + _columns) % _columns; // Wrap around edges
        int ny = (y + dy + _rows) % _rows;
        
        if (_grid[nx][ny] == 1) {
          count++;
        }
      }
    }
    
    return count;
  }
  
  /// Count neighbors of a specific state
  int _countSpecificStateNeighbors(int x, int y, int state) {
    int count = 0;
    
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip self
        
        int nx = (x + dx + _columns) % _columns; // Wrap around edges
        int ny = (y + dy + _rows) % _rows;
        
        if (_grid[nx][ny] == state) {
          count++;
        }
      }
    }
    
    return count;
  }
  
  /// Handle interaction effects on the grid
  void _handleInteractionEffects() {
    if (_interactionPoint == null) return;
    
    // Convert interaction point to grid coordinates
    final gridX = (_interactionPoint!.dx / _cellSize).floor();
    final gridY = (_interactionPoint!.dy / _cellSize).floor();
    
    // Enforce bounds
    if (gridX < 0 || gridX >= _columns || gridY < 0 || gridY >= _rows) {
      return;
    }
    
    final radius = parameters.interactionRadius / _cellSize;
    
    // Add cells in a radius around the interaction point
    for (int dx = -radius.floor(); dx <= radius.floor(); dx++) {
      for (int dy = -radius.floor(); dy <= radius.floor(); dy++) {
        final x = (gridX + dx + _columns) % _columns;
        final y = (gridY + dy + _rows) % _rows;
        
        // Check if within radius
        if (dx * dx + dy * dy <= radius * radius) {
          switch (_automataType) {
            case AutomataType.gameOfLife:
            case AutomataType.seeds:
            case AutomataType.custom:
            case AutomataType.elementary:
              _grid[x][y] = 1;
              break;
              
            case AutomataType.briansBrain:
              _grid[x][y] = 1;
              break;
              
            case AutomataType.wireworld:
              _grid[x][y] = 3; // Add conductor on interaction
              break;
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = parameters.backgroundColor,
    );
    
    // Draw grid
    final cellPaint = Paint();
    
    for (int x = 0; x < _columns; x++) {
      for (int y = 0; y < _rows; y++) {
        final state = _grid[x][y];
        
        if (state > 0) { // Only draw non-empty cells
          cellPaint.color = _stateColors[state % _stateColors.length];
          
          canvas.drawRect(
            Rect.fromLTWH(
              x * _cellSize, 
              y * _cellSize, 
              _cellSize, 
              _cellSize
            ),
            cellPaint,
          );
        }
      }
    }
    
    // Draw grid lines if enabled
    if (parameters.algorithmSpecificParams['showGrid'] == true) {
      _renderGridLines(canvas, size);
    }
    
    // Draw interaction indicator if active
    if (parameters.interactionEnabled && _interactionPoint != null && _interactionActive) {
      canvas.drawCircle(
        _interactionPoint!,
        parameters.interactionRadius,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
  
  /// Render grid lines
  void _renderGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Draw vertical lines
    for (int x = 0; x <= _columns; x++) {
      canvas.drawLine(
        Offset(x * _cellSize, 0),
        Offset(x * _cellSize, size.height),
        gridPaint,
      );
    }
    
    // Draw horizontal lines
    for (int y = 0; y <= _rows; y++) {
      canvas.drawLine(
        Offset(0, y * _cellSize),
        Offset(size.width, y * _cellSize),
        gridPaint,
      );
    }
  }

  @override
  void handleInteraction(Offset? position, bool isPressed) {
    _interactionPoint = position;
    _interactionActive = isPressed;
  }

  @override
  void reset() {
    initialize();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    final needsReset = 
        parameters.canvasSize != newParameters.canvasSize ||
        parameters.algorithmSpecificParams != newParameters.algorithmSpecificParams;
    
    parameters.copyWith(
      canvasSize: newParameters.canvasSize,
      colorPalette: newParameters.colorPalette,
      backgroundColor: newParameters.backgroundColor,
      interactionEnabled: newParameters.interactionEnabled,
      interactionRadius: newParameters.interactionRadius,
      algorithmSpecificParams: newParameters.algorithmSpecificParams,
    );
    
    // Update colors if palette changed
    if (parameters.colorPalette != newParameters.colorPalette) {
      _initializeColors();
    }
    
    if (needsReset) {
      initialize();
    }
  }

  @override
  void dispose() {
    _grid.clear();
    _nextGrid.clear();
  }
}