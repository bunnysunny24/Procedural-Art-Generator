import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/art_parameters.dart';

class ParameterControls extends StatelessWidget {
  final ArtParameters parameters;
  final Function(ArtParameters) onParametersChanged;

  const ParameterControls({
    Key? key,
    required this.parameters,
    required this.onParametersChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Particles'),
            _buildParticleTypeSelector(),
            _buildSlider(
              label: 'Particle Count',
              value: parameters.particleCount.toDouble(),
              min: 10,
              max: 2000,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  particleCount: value.toInt(),
                ));
              },
            ),
            _buildSlider(
              label: 'Min Size',
              value: parameters.minParticleSize,
              min: 1,
              max: 20,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  minParticleSize: value,
                ));
              },
            ),
            _buildSlider(
              label: 'Max Size',
              value: parameters.maxParticleSize,
              min: 5,
              max: 50,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  maxParticleSize: value,
                ));
              },
            ),
            
            _buildSectionHeader('Animation'),
            _buildAnimationTypeSelector(),
            _buildSlider(
              label: 'Speed',
              value: parameters.speed,
              min: 0.1,
              max: 3.0,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  speed: value,
                ));
              },
            ),
            _buildSlider(
              label: 'Friction',
              value: parameters.friction,
              min: 0.0,
              max: 0.1,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  friction: value,
                ));
              },
            ),
            _buildSlider(
              label: 'Turbulence',
              value: parameters.turbulence,
              min: 0.0,
              max: 2.0,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  turbulence: value,
                ));
              },
            ),
            
            _buildSectionHeader('Physics'),
            _buildSlider(
              label: 'Gravity',
              value: parameters.gravity,
              min: -0.2,
              max: 0.2,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  gravity: value,
                ));
              },
            ),
            _buildSlider(
              label: 'Wind',
              value: parameters.wind,
              min: -0.2,
              max: 0.2,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  wind: value,
                ));
              },
            ),
            _buildSwitch(
              label: 'Collision',
              value: parameters.collisionEnabled,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  collisionEnabled: value,
                ));
              },
            ),
            
            _buildSectionHeader('Color'),
            _buildColorModeSelector(),
            if (parameters.colorMode == ColorMode.single || 
                parameters.colorMode == ColorMode.gradient) 
              _buildColorPickers(context),
            if (parameters.colorMode == ColorMode.custom)
              _buildCustomColorPalette(context),
            
            _buildSectionHeader('Interaction'),
            _buildSwitch(
              label: 'Gesture Enabled',
              value: parameters.gestureEnabled,
              onChanged: (value) {
                onParametersChanged(parameters.copyWith(
                  gestureEnabled: value,
                ));
              },
            ),
            if (parameters.gestureEnabled)
              _buildSlider(
                label: 'Interaction Strength',
                value: parameters.interactionStrength,
                min: 0.1,
                max: 3.0,
                onChanged: (value) {
                  onParametersChanged(parameters.copyWith(
                    interactionStrength: value,
                  ));
                },
              ),
            
            _buildSectionHeader('Canvas'),
            _buildColorPickerButton(
              label: 'Background',
              color: parameters.backgroundColor,
              onColorChanged: (color) {
                onParametersChanged(parameters.copyWith(
                  backgroundColor: color,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value.toStringAsFixed(2)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildParticleTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Particle Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ParticleType.values.map((type) {
              return ChoiceChip(
                label: Text(_getParticleTypeName(type)),
                selected: parameters.particleType == type,
                onSelected: (selected) {
                  if (selected) {
                    onParametersChanged(parameters.copyWith(
                      particleType: type,
                    ));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Animation Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: AnimationType.values.map((type) {
              return ChoiceChip(
                label: Text(_getAnimationTypeName(type)),
                selected: parameters.animationType == type,
                onSelected: (selected) {
                  if (selected) {
                    onParametersChanged(parameters.copyWith(
                      animationType: type,
                    ));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color Mode'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ColorMode.values.map((mode) {
              return ChoiceChip(
                label: Text(_getColorModeName(mode)),
                selected: parameters.colorMode == mode,
                onSelected: (selected) {
                  if (selected) {
                    onParametersChanged(parameters.copyWith(
                      colorMode: mode,
                    ));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickers(BuildContext context) {
    return Column(
      children: [
        _buildColorPickerButton(
          label: 'Primary Color',
          color: parameters.primaryColor,
          onColorChanged: (color) {
            onParametersChanged(parameters.copyWith(
              primaryColor: color,
            ));
          },
        ),
        if (parameters.colorMode == ColorMode.gradient)
          _buildColorPickerButton(
            label: 'Secondary Color',
            color: parameters.secondaryColor,
            onColorChanged: (color) {
              onParametersChanged(parameters.copyWith(
                secondaryColor: color,
              ));
            },
          ),
      ],
    );
  }

  Widget _buildColorPickerButton({
    required String label,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _showColorPicker(
                context: context,
                color: color,
                onColorChanged: onColorChanged,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorPalette(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Custom Colors'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ...parameters.customColors.asMap().entries.map((entry) {
              final index = entry.key;
              final color = entry.value;
              return GestureDetector(
                onTap: () {
                  _showColorPicker(
                    context: context,
                    color: color,
                    onColorChanged: (newColor) {
                      final newColors = List<Color>.from(parameters.customColors);
                      newColors[index] = newColor;
                      onParametersChanged(parameters.copyWith(
                        customColors: newColors,
                      ));
                    },
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            }),
            // Add button
            GestureDetector(
              onTap: () {
                if (parameters.customColors.length < 10) {
                  final newColors = List<Color>.from(parameters.customColors);
                  newColors.add(Colors.white);
                  onParametersChanged(parameters.copyWith(
                    customColors: newColors,
                  ));
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker({
    required BuildContext context,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = color;
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  String _getParticleTypeName(ParticleType type) {
    switch (type) {
      case ParticleType.circle:
        return 'Circle';
      case ParticleType.square:
        return 'Square';
      case ParticleType.triangle:
        return 'Triangle';
      case ParticleType.line:
        return 'Line';
      case ParticleType.custom:
        return 'Star';
    }
  }

  String _getAnimationTypeName(AnimationType type) {
    switch (type) {
      case AnimationType.flow:
        return 'Flow';
      case AnimationType.explode:
        return 'Explode';
      case AnimationType.swirl:
        return 'Swirl';
      case AnimationType.bounce:
        return 'Bounce';
      case AnimationType.random:
        return 'Random';
    }
  }

  String _getColorModeName(ColorMode mode) {
    switch (mode) {
      case ColorMode.single:
        return 'Single';
      case ColorMode.gradient:
        return 'Gradient';
      case ColorMode.rainbow:
        return 'Rainbow';
      case ColorMode.custom:
        return 'Custom';
    }
  }
}