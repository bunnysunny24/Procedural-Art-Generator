import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import 'art_parameters.dart';
import 'particle_system.dart';

enum ExportFormat { png, jpg, svg }

class ArtService {
  static const String _savedParametersKey = 'saved_art_parameters';
  final ArtParameters params;

  ArtService(this.params);
  
  // Save parameters to local storage
  static Future<bool> saveParameters(ArtParameters parameters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedParameters = prefs.getStringList(_savedParametersKey) ?? [];
      
      // Convert parameters to JSON
      final paramsJson = jsonEncode(parameters.toJson());
      
      // Check if this ID already exists and update it
      bool found = false;
      List<String> updatedParams = [];
      
      for (var paramStr in savedParameters) {
        final param = jsonDecode(paramStr);
        if (param['id'] == parameters.id) {
          updatedParams.add(paramsJson);
          found = true;
        } else {
          updatedParams.add(paramStr);
        }
      }
      
      // If not found, add it
      if (!found) {
        updatedParams.add(paramsJson);
      }
      
      // Save updated list
      await prefs.setStringList(_savedParametersKey, updatedParams);
      return true;
    } catch (e) {
      print('Error saving parameters: $e');
      return false;
    }
  }
  
  // Load all saved parameters
  static Future<List<ArtParameters>> loadAllParameters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedParameters = prefs.getStringList(_savedParametersKey) ?? [];
      
      return savedParameters.map((paramStr) {
        final json = jsonDecode(paramStr);
        return ArtParameters.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading parameters: $e');
      return [];
    }
  }
  
  // Delete saved parameters
  static Future<bool> deleteParameters(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedParameters = prefs.getStringList(_savedParametersKey) ?? [];
      
      List<String> updatedParams = [];
      
      for (var paramStr in savedParameters) {
        final param = jsonDecode(paramStr);
        if (param['id'] != id) {
          updatedParams.add(paramStr);
        }
      }
      
      await prefs.setStringList(_savedParametersKey, updatedParams);
      return true;
    } catch (e) {
      print('Error deleting parameters: $e');
      return false;
    }
  }
  
  // Export artwork as an image file
  static Future<String?> exportArtwork(
    ParticleSystem particleSystem, 
    ExportFormat format,
    {String? customName}
  ) async {
    try {
      // Capture image from canvas
      final ui.Image image = await captureImage(particleSystem);
      
      // Convert to bytes
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Convert to proper format if needed
      Uint8List finalBytes;
      String extension;
      
      switch (format) {
        case ExportFormat.jpg:
          final imgData = img.decodePng(pngBytes);
          if (imgData == null) return null;
          finalBytes = Uint8List.fromList(img.encodeJpg(imgData, quality: 90));
          extension = 'jpg';
          break;
        case ExportFormat.png:
          finalBytes = pngBytes;
          extension = 'png';
          break;
        case ExportFormat.svg:
          // SVG generation would require different approach
          throw UnimplementedError('SVG export not yet implemented');
      }
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = customName ?? 'generative_art_$timestamp';
      final filename = '$name.$extension';
      
      // Save to temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(finalBytes);
      
      return file.path;
    } catch (e) {
      print('Error exporting artwork: $e');
      return null;
    }
  }
  
  // Share artwork
  static Future<void> shareArtwork(ParticleSystem particleSystem) async {
    try {
      final filePath = await exportArtwork(particleSystem, ExportFormat.png);
      if (filePath != null) {
        await Share.shareFiles([filePath], text: 'Check out my generative art!');
      }
    } catch (e) {
      print('Error sharing artwork: $e');
    }
  }
  
  // Save artwork to gallery or file
  Future<String?> saveArtworkToFile() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Artwork',
        fileName: 'artwork.png',
        allowedExtensions: ['png'],
      );

      if (result != null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_artwork.png';
        final tempFile = File(tempPath);
        
        // Save the artwork to temporary file
        await _saveCanvasToFile(tempFile);
        
        // Copy to final destination
        await tempFile.copy(result);
        await tempFile.delete();
        
        return result;
      }
    } catch (e) {
      debugPrint('Error saving artwork: $e');
    }
    return null;
  }
  
  // Helper to capture image from particle system
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

  Future<void> _saveCanvasToFile(File file) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw the current state
      final size = params.canvasSize;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = params.backgroundColor,
      );
      
      // Get the current state of the canvas
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        params.canvasSize.width.toInt(),
        params.canvasSize.height.toInt()
      );
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer;
      
      if (buffer != null) {
        await file.writeAsBytes(
          buffer.asUint8List(byteData!.offsetInBytes, byteData.lengthInBytes)
        );
      }
    } catch (e) {
      debugPrint('Error in _saveCanvasToFile: $e');
      rethrow;
    }
  }
}