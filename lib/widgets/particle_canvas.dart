import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/art_parameters.dart';
import '../models/particle_system.dart';

class ParticleCanvas extends StatefulWidget {
  final ArtParameters parameters;
  final void Function(Offset?)? onInteraction;

  const ParticleCanvas({
    Key? key,
    required this.parameters,
    this.onInteraction,
  }) : super(key: key);

  @override
  State<ParticleCanvas> createState() => _ParticleCanvasState();
}

class _ParticleCanvasState extends State<ParticleCanvas> with SingleTickerProviderStateMixin {
  late ParticleSystem particleSystem;
  late AnimationController _animationController;
  Offset? _currentOffset;
  
  @override
  void initState() {
    super.initState();
    particleSystem = ParticleSystem(widget.parameters);
    
    // Set up the animation controller for continuous rendering
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1), // Long duration to keep it running
    )..repeat();
    
    _animationController.addListener(_updateAnimation);
  }
  
  @override
  void dispose() {
    _animationController.removeListener(_updateAnimation);
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(ParticleCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parameters != oldWidget.parameters) {
      particleSystem.updateParameters(widget.parameters);
    }
  }
  
  void _updateAnimation() {
    particleSystem.update();
    // This will mark the widget for rebuild
    setState(() {});
  }
  
  void _handleGestureUpdate(Offset? localPosition) {
    _currentOffset = localPosition;
    widget.onInteraction?.call(localPosition);
    particleSystem.handleInteraction(localPosition);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.parameters.gestureEnabled
          ? (details) => _handleGestureUpdate(details.localPosition)
          : null,
      onPanUpdate: widget.parameters.gestureEnabled
          ? (details) => _handleGestureUpdate(details.localPosition)
          : null,
      onPanEnd: widget.parameters.gestureEnabled
          ? (_) => _handleGestureUpdate(null)
          : null,
      child: ClipRect(
        child: CustomPaint(
          size: widget.parameters.canvasSize,
          painter: ParticlePainter(
            particleSystem: particleSystem,
            interactionPoint: _currentOffset,
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final ParticleSystem particleSystem;
  final Offset? interactionPoint;
  
  ParticlePainter({
    required this.particleSystem,
    this.interactionPoint,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Fill the background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = particleSystem.params.backgroundColor,
    );
    
    // Draw all particles
    particleSystem.render(canvas);
    
    // Optional: draw interaction indicator
    if (interactionPoint != null && particleSystem.params.gestureEnabled) {
      final radius = 20.0 * particleSystem.params.interactionStrength;
      canvas.drawCircle(
        interactionPoint!,
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// Helper class to export canvas as image
class CanvasImageExporter {
  static Future<ui.Image> captureImage(ParticleSystem particleSystem) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = particleSystem.params.canvasSize;
    
    // Fill the background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = particleSystem.params.backgroundColor,
    );
    
    // Draw all particles
    particleSystem.render(canvas);
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }
}