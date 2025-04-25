import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../core/algorithms/algorithm_factory.dart';
import '../core/models/parameter_set.dart';

/// Custom painter for rendering the generative art
class ArtPainter extends CustomPainter {
  /// The algorithm that generates the art
  final GenerativeAlgorithm algorithm;
  
  /// Whether to capture the current frame to an image
  final bool capture;
  
  /// Callback function for when a capture is completed
  final Function(ui.Image)? onCaptureComplete;
  
  ArtPainter({
    required this.algorithm,
    this.capture = false,
    this.onCaptureComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a background rectangle
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Render the algorithm to the canvas
    algorithm.render(canvas);
    
    // Capture image if requested
    if (capture && onCaptureComplete != null) {
      _captureImage(canvas, size);
    }
  }
  
  /// Capture the current canvas state as an image
  Future<void> _captureImage(Canvas canvas, Size size) async {
    final recorder = ui.PictureRecorder();
    final captureCanvas = Canvas(recorder);
    
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
      
    captureCanvas.drawRect(Offset.zero & size, bgPaint);
    
    // Render algorithm to capture canvas
    algorithm.render(captureCanvas);
    
    // Create picture and image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    
    onCaptureComplete?.call(image);
  }

  @override
  bool shouldRepaint(ArtPainter oldDelegate) => true;
}

/// Widget for displaying and interacting with generative art
class ArtCanvas extends StatefulWidget {
  /// Parameters for the art algorithm
  final ParameterSet parameters;
  
  /// Whether to animate the art
  final bool animate;
  
  /// Callback when the user interacts with the canvas
  final Function(ParameterSet)? onParametersChanged;
  
  const ArtCanvas({
    super.key,
    required this.parameters,
    this.animate = true,
    this.onParametersChanged,
  });

  @override
  State<ArtCanvas> createState() => _ArtCanvasState();
}

class _ArtCanvasState extends State<ArtCanvas>
    with SingleTickerProviderStateMixin {
  /// Animation controller for updates
  late AnimationController _controller;
  
  /// The algorithm that generates the art
  late GenerativeAlgorithm _algorithm;
  
  /// The current interaction point
  Offset? _interactionPoint;
  
  /// Whether we're currently capturing an image
  bool _capturing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Create the algorithm based on parameters
    _algorithm = AlgorithmFactory.createAlgorithm(widget.parameters);
    
    // Set up animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Add listener for animation updates
    _controller.addListener(_updateAnimation);
    
    // Start animation if enabled
    if (widget.animate) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(ArtCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update algorithm if parameters changed
    if (widget.parameters != oldWidget.parameters) {
      _algorithm.updateParameters(widget.parameters);
    }
    
    // Update animation state
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }
  
  /// Update the animation state
  void _updateAnimation() {
    if (mounted) {
      _algorithm.update();
      setState(() {});
    }
  }
  
  /// Handle pointer down event
  void _handlePointerDown(PointerDownEvent event) {
    _interactionPoint = event.localPosition;
    _algorithm.handleInteraction(_interactionPoint);
  }
  
  /// Handle pointer move event
  void _handlePointerMove(PointerMoveEvent event) {
    _interactionPoint = event.localPosition;
    _algorithm.handleInteraction(_interactionPoint);
  }
  
  /// Handle pointer up event
  void _handlePointerUp(PointerUpEvent event) {
    _interactionPoint = null;
    _algorithm.handleInteraction(null);
  }
  
  /// Capture the current state as an image
  Future<ui.Image?> captureImage() async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    
    setState(() {
      _capturing = true;
    });
    
    // Wait for next frame to ensure state is updated
    await Future.delayed(Duration.zero);
    
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.parameters.interactionEnabled ? _handlePointerDown : null,
      onPointerMove: widget.parameters.interactionEnabled ? _handlePointerMove : null,
      onPointerUp: widget.parameters.interactionEnabled ? _handlePointerUp : null,
      child: CustomPaint(
        painter: ArtPainter(
          algorithm: _algorithm,
          capture: _capturing,
          onCaptureComplete: (image) {
            setState(() {
              _capturing = false;
            });
            _captureCompleter?.complete(image);
            _captureCompleter = null;
          },
        ),
        size: Size.infinite,
      ),
    );
  }
  
  // Completer for image capture
  Completer<ui.Image>? _captureCompleter;
  
  @override
  void dispose() {
    _controller.dispose();
    _captureCompleter?.completeError('Canvas disposed');
    super.dispose();
  }
}