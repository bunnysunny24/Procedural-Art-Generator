import 'dart:math';
import 'package:flutter/material.dart' hide Colors;
import '../models/parameter_set.dart';
import 'generative_algorithm.dart';

enum AutomataType {
  gameOfLife,
  seeds,
  briansBrain,
  wireworld,
  elementary,
  custom,
}

class CellularAutomataAlgorithm extends GenerativeAlgorithm {
  late List<List<int>> _grid;
  late List<List<int>> _nextGrid;
  late int _rows;
  late int _columns;
  late AutomataType _automataType;
  int _generation = 0;
  final Random _random = Random();
  final double _cellSize = 10.0;

  CellularAutomataAlgorithm(ParameterSet parameters) : super(parameters) {
    _initialize();
  }

  void _initialize() {
    final typeIndex = parameters.algorithmSpecificParams['automataType'] as int? ?? 0;
    _automataType = AutomataType.values[typeIndex];
    
    _columns = (parameters.canvasSize.width / _cellSize).ceil();
    _rows = (parameters.canvasSize.height / _cellSize).ceil();
    
    _grid = List.generate(_rows, (_) => List.filled(_columns, 0));
    _nextGrid = List.generate(_rows, (_) => List.filled(_columns, 0));
    
    _randomizeCells();
  }

  void _randomizeCells() {
    final density = parameters.algorithmSpecificParams['initialDensity'] as double? ?? 0.3;
    
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _columns; x++) {
        _grid[y][x] = _random.nextDouble() < density ? 1 : 0;
      }
    }
  }

  @override
  void update(Duration delta) {
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _columns; x++) {
        _updateCell(x, y);
      }
    }

    // Swap grids
    final temp = _grid;
    _grid = _nextGrid;
    _nextGrid = temp;

    _generation++;

    // Auto reset if enabled
    if (parameters.algorithmSpecificParams['autoReset'] == true &&
        _generation > (parameters.algorithmSpecificParams['resetGenerations'] ?? 100)) {
      reset();
    }
  }

  void _updateCell(int x, int y) {
    final neighbors = _countNeighbors(x, y);
    final currentState = _grid[y][x];

    switch (_automataType) {
      case AutomataType.gameOfLife:
        _nextGrid[y][x] = _applyGameOfLifeRules(currentState, neighbors);
        break;
      case AutomataType.seeds:
        _nextGrid[y][x] = _applySeedsRules(currentState, neighbors);
        break;
      case AutomataType.briansBrain:
        _nextGrid[y][x] = _applyBriansBrainRules(currentState, neighbors);
        break;
      case AutomataType.wireworld:
        _nextGrid[y][x] = _applyWireworldRules(x, y);
        break;
      case AutomataType.elementary:
        _nextGrid[y][x] = _applyElementaryRules(x, y);
        break;
      case AutomataType.custom:
        _nextGrid[y][x] = _applyCustomRules(currentState, neighbors);
        break;
    }
  }

  int _countNeighbors(int x, int y) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        
        final newX = (x + i + _columns) % _columns;
        final newY = (y + j + _rows) % _rows;
        
        count += _grid[newY][newX];
      }
    }
    return count;
  }

  int _applyGameOfLifeRules(int state, int neighbors) {
    if (state == 1) {
      return (neighbors == 2 || neighbors == 3) ? 1 : 0;
    } else {
      return neighbors == 3 ? 1 : 0;
    }
  }

  int _applySeedsRules(int state, int neighbors) {
    return state == 0 && neighbors == 2 ? 1 : 0;
  }

  int _applyBriansBrainRules(int state, int neighbors) {
    if (state == 2) return 1;      // Dying -> Dead
    if (state == 1) return 0;      // Alive -> Dying
    return neighbors == 2 ? 2 : 0;  // Dead -> Alive if exactly 2 neighbors
  }

  int _applyWireworldRules(int x, int y) {
    final state = _grid[y][x];
    final electronHeadCount = _countSpecificNeighbors(x, y, 1);
    
    switch (state) {
      case 1: return 2;        // Electron head -> Electron tail
      case 2: return 3;        // Electron tail -> Conductor
      case 3: return electronHeadCount == 1 || electronHeadCount == 2 ? 1 : 3;  // Conductor -> Electron head
      default: return 0;       // Empty stays empty
    }
  }

  int _applyElementaryRules(int x, int y) {
    if (y == _rows - 1) return 0;  // Bottom row stays empty
    
    final left = x > 0 ? _grid[y][x - 1] : _grid[y][_columns - 1];
    final center = _grid[y][x];
    final right = x < _columns - 1 ? _grid[y][x + 1] : _grid[y][0];
    
    final ruleNumber = parameters.algorithmSpecificParams['elementaryRule'] as int? ?? 30;
    final pattern = (left << 2) | (center << 1) | right;
    
    return (ruleNumber >> pattern) & 1;
  }

  int _applyCustomRules(int state, int neighbors) {
    final birthRange = parameters.algorithmSpecificParams['birthRange'] as List<int>? ?? [3];
    final survivalRange = parameters.algorithmSpecificParams['survivalRange'] as List<int>? ?? [2, 3];
    
    if (state == 1) {
      return survivalRange.contains(neighbors) ? 1 : 0;
    } else {
      return birthRange.contains(neighbors) ? 1 : 0;
    }
  }

  int _countSpecificNeighbors(int x, int y, int targetState) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        
        final newX = (x + i + _columns) % _columns;
        final newY = (y + j + _rows) % _rows;
        
        if (_grid[newY][newX] == targetState) count++;
      }
    }
    return count;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & parameters.canvasSize,
      Paint()..color = parameters.backgroundColor,
    );

    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _columns; x++) {
        if (_grid[y][x] > 0) {
          _drawCell(canvas, x, y);
        }
      }
    }

    if (parameters.algorithmSpecificParams['showGrid'] == true) {
      _drawGrid(canvas);
    }
  }

  void _drawCell(Canvas canvas, int x, int y) {
    final rect = Rect.fromLTWH(
      x * _cellSize,
      y * _cellSize,
      _cellSize - 1,
      _cellSize - 1,
    );

    final color = _getCellColor(_grid[y][x]);
    canvas.drawRect(rect, Paint()..color = color);
  }

  Color _getCellColor(int state) {
    switch (_automataType) {
      case AutomataType.wireworld:
        switch (state) {
          case 1: return const Color(0xFFFFFF00);  // Electron head (yellow)
          case 2: return const Color(0xFF0000FF);  // Electron tail (blue)
          case 3: return const Color(0xFFFF0000);  // Conductor (red)
          default: return Colors.black;
        }
      case AutomataType.briansBrain:
        switch (state) {
          case 2: return const Color(0xFFFFFFFF);  // Alive (white)
          case 1: return const Color(0xFF666666);  // Dying (gray)
          default: return Colors.black;
        }
      default:
        return state > 0 ? parameters.colorPalette.getColorAtProgress(state / 3) : Colors.black;
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int x = 0; x <= _columns; x++) {
      canvas.drawLine(
        Offset(x * _cellSize, 0),
        Offset(x * _cellSize, _rows * _cellSize),
        paint,
      );
    }

    for (int y = 0; y <= _rows; y++) {
      canvas.drawLine(
        Offset(0, y * _cellSize),
        Offset(_columns * _cellSize, y * _cellSize),
        paint,
      );
    }
  }

  @override
  void handleInput(Offset position, bool isActive) {
    if (!isActive) return;
    
    final x = (position.dx / _cellSize).floor();
    final y = (position.dy / _cellSize).floor();
    
    if (x >= 0 && x < _columns && y >= 0 && y < _rows) {
      final radius = (parameters.interactionRadius / _cellSize).ceil();
      
      for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
          final dx = x + i;
          final dy = y + j;
          
          if (dx >= 0 && dx < _columns && dy >= 0 && dy < _rows) {
            final distance = sqrt(i * i + j * j);
            if (distance <= radius) {
              _grid[dy][dx] = 1;
            }
          }
        }
      }
    }
  }

  @override
  void reset() {
    _generation = 0;
    _randomizeCells();
  }

  @override
  void updateParameters(ParameterSet newParameters) {
    final needsReset = 
      parameters.canvasSize != newParameters.canvasSize ||
      parameters.algorithmSpecificParams != newParameters.algorithmSpecificParams;

    if (needsReset) {
      _initialize();
    }
  }
}