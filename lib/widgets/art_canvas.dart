import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/algorithms/algorithm_factory.dart';
import '../core/algorithms/generative_algorithm.dart';
import '../core/models/parameter_set.dart';

/// Custom painter for rendering the generative art
class _ArtPainter extends CustomPainter {
  final GenerativeAlgorithm algorithm;

  _ArtPainter(this.algorithm);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, bgPaint);
    algorithm.render(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget for displaying and interacting with generative art
class ArtCanvas extends StatefulWidget {
  final ParameterSet parameters;

  const ArtCanvas({
    super.key,
    required this.parameters,
  });

  @override
  State<ArtCanvas> createState() => _ArtCanvasState();
}

class _ArtCanvasState extends State<ArtCanvas> with SingleTickerProviderStateMixin {
  late GenerativeAlgorithm _algorithm;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..repeat();
    _algorithm = AlgorithmFactory.createAlgorithm(widget.parameters);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ArtCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parameters != oldWidget.parameters) {
      _algorithm = AlgorithmFactory.createAlgorithm(widget.parameters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.parameters.interactionEnabled ? _handlePanUpdate : null,
      child: CustomPaint(
        painter: _ArtPainter(_algorithm),
        size: Size.infinite,
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    _algorithm.handleInput(localPosition, true);
  }
}