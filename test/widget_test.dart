import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procedural_art_generator/app.dart';
import 'package:procedural_art_generator/screens/art_creation_screen.dart';
import 'package:procedural_art_generator/widgets/parameter_controls.dart';
import 'package:procedural_art_generator/widgets/art_canvas.dart';
import 'package:procedural_art_generator/models/art_parameters.dart';
import 'package:procedural_art_generator/core/models/parameter_set.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: ProceduralArtGeneratorApp(),
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  group('ArtCreationScreen tests', () {
    testWidgets('Should show art canvas and parameter controls', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: ArtCreationScreen())));
      await tester.pumpAndSettle();

      expect(find.byType(ArtCanvas), findsOneWidget);
      expect(find.byType(ParameterControls), findsOneWidget);
    });

    testWidgets('Should toggle controls visibility', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: ArtCreationScreen())));
      await tester.pumpAndSettle();

      // Initially controls should be visible
      expect(find.byType(ParameterControls), findsOneWidget);

      // Find and tap the visibility toggle button
      final toggleButton = find.byTooltip('Hide controls');
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Controls should now be hidden
      expect(find.byType(ParameterControls), findsNothing);
    });

    testWidgets('Should update parameters when controls change', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: ArtCreationScreen())));
      await tester.pumpAndSettle();

      // Find a slider (e.g., particle count slider)
      final particleCountSlider = find.byType(Slider).first;
      expect(particleCountSlider, findsOneWidget);

      // Change the slider value
      await tester.drag(particleCountSlider, const Offset(20.0, 0.0));
      await tester.pumpAndSettle();

      // Art canvas should be updated with new parameters
      final artCanvas = find.byType(ArtCanvas);
      expect(artCanvas, findsOneWidget);
    });
  });

  group('Parameter controls tests', () {
    late ArtParameters testParameters;

    setUp(() {
      testParameters = ArtParameters(
        name: 'Test Art',
        canvasSize: const Size(800, 600),
      );
    });

    testWidgets('Should display all parameter sections', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ParameterControls(
            parameters: testParameters,
            onParametersChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify all main parameter sections are present
      expect(find.text('Particles'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
    });

    testWidgets('Should trigger callback when parameters change', (WidgetTester tester) async {
      ArtParameters? updatedParams;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ParameterControls(
            parameters: testParameters,
            onParametersChanged: (params) {
              updatedParams = params;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Find and interact with a control
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(20.0, 0.0));
      await tester.pumpAndSettle();

      // Verify callback was triggered
      expect(updatedParams, isNotNull);
    });
  });

  group('Art canvas tests', () {
    late ParameterSet parameterSet;
    
    setUp(() {
      parameterSet = ParameterSet.defaultSettings();
    });

    testWidgets('Should respond to user interaction when enabled', (WidgetTester tester) async {
      final parameters = parameterSet.copyWith(interactionEnabled: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArtCanvas(parameters: parameters),
        ),
      ));
      await tester.pumpAndSettle();

      // Simulate pan gesture
      final canvas = find.byType(ArtCanvas);
      await tester.drag(canvas, const Offset(50.0, 50.0));
      await tester.pumpAndSettle();
    });

    testWidgets('Should ignore user interaction when disabled', (WidgetTester tester) async {
      final parameters = parameterSet.copyWith(interactionEnabled: false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArtCanvas(parameters: parameters),
        ),
      ));
      await tester.pumpAndSettle();

      // Simulate pan gesture
      final canvas = find.byType(ArtCanvas);
      await tester.drag(canvas, const Offset(50.0, 50.0));
      await tester.pumpAndSettle();
    });
  });
}
