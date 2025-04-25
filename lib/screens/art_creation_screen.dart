import 'package:flutter/material.dart';
import '../models/art_parameters.dart';
import '../models/art_service.dart';
import '../widgets/particle_canvas.dart';
import '../widgets/parameter_controls.dart';

class ArtCreationScreen extends StatefulWidget {
  const ArtCreationScreen({Key? key}) : super(key: key);

  @override
  State<ArtCreationScreen> createState() => _ArtCreationScreenState();
}

class _ArtCreationScreenState extends State<ArtCreationScreen> {
  late ArtParameters parameters;
  bool controlsVisible = true;
  bool isSaving = false;
  bool isExporting = false;
  final GlobalKey canvasKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    parameters = ArtParameters();
  }
  
  void _updateParameters(ArtParameters newParams) {
    setState(() {
      parameters = newParams;
    });
  }
  
  void _toggleControls() {
    setState(() {
      controlsVisible = !controlsVisible;
    });
  }
  
  Future<void> _saveParameters() async {
    setState(() {
      isSaving = true;
    });
    
    try {
      final String? name = await _showNameDialog(
        initialName: parameters.name,
      );
      
      if (name != null && name.isNotEmpty) {
        final updatedParams = parameters.copyWith(name: name);
        final success = await ArtService.saveParameters(updatedParams);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parameters saved successfully')),
          );
          setState(() {
            parameters = updatedParams;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save parameters')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }
  
  Future<void> _loadParameters() async {
    try {
      final savedParams = await ArtService.loadAllParameters();
      if (savedParams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved parameters found')),
        );
        return;
      }
      
      final selectedParams = await _showLoadDialog(savedParams);
      if (selectedParams != null) {
        setState(() {
          parameters = selectedParams;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading parameters: $e')),
      );
    }
  }
  
  Future<void> _exportArtwork() async {
    setState(() {
      isExporting = true;
    });
    
    try {
      final format = await _showExportFormatDialog();
      if (format == null) return;
      
      if (canvasKey.currentContext == null) return;

      final artService = ArtService(parameters);
      final filePath = await artService.saveArtworkToFile();
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artwork exported to: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled or failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting artwork: $e')),
      );
    } finally {
      setState(() {
        isExporting = false;
      });
    }
  }
  
  Future<void> _shareArtwork() async {
    try {
      if (canvasKey.currentContext == null) return;
      await ArtService.shareArtwork(canvasKey);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing artwork: $e')),
      );
    }
  }
  
  Future<String?> _showNameDialog({required String initialName}) async {
    final controller = TextEditingController(text: initialName);
    
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Name Your Creation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter a name for your artwork',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  Future<ArtParameters?> _showLoadDialog(List<ArtParameters> savedParams) async {
    return showDialog<ArtParameters>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Load Saved Parameters'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: savedParams.length,
              itemBuilder: (context, index) {
                final param = savedParams[index];
                return ListTile(
                  title: Text(param.name),
                  subtitle: Text('Created on ${DateTime.now().toString().split('.')[0]}'),
                  onTap: () => Navigator.of(context).pop(param),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await ArtService.deleteParameters(param.id);
                      Navigator.of(context).pop();
                      _loadParameters(); // Refresh the dialog
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Future<ExportFormat?> _showExportFormatDialog() async {
    return showDialog<ExportFormat>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Export Format'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(ExportFormat.png),
              child: const Text('PNG - High quality with transparency'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(ExportFormat.jpg),
              child: const Text('JPG - Smaller file size'),
            ),
            // SVG not implemented yet
            // SimpleDialogOption(
            //   onPressed: () => Navigator.of(context).pop(ExportFormat.svg),
            //   child: const Text('SVG - Vector format (experimental)'),
            // ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parameters.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isSaving ? null : _saveParameters,
            tooltip: 'Save parameters',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _loadParameters,
            tooltip: 'Load parameters',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArtwork,
            tooltip: 'Share artwork',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: isExporting ? null : _exportArtwork,
            tooltip: 'Export artwork',
          ),
          IconButton(
            icon: Icon(controlsVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleControls,
            tooltip: controlsVisible ? 'Hide controls' : 'Show controls',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Canvas area
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ParticleCanvas(
                    key: canvasKey,
                    parameters: parameters,
                  ),
                ),
              ),
            ),
            
            // Controls panel
            if (controlsVisible)
              Container(
                width: 300,
                color: Theme.of(context).cardColor,
                child: ParameterControls(
                  parameters: parameters,
                  onParametersChanged: _updateParameters,
                ),
              ),
          ],
        ),
      ),
    );
  }
}