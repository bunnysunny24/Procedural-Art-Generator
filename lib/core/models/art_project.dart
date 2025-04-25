import 'dart:ui';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'parameter_set.dart';

/// Represents a saved art project with metadata and generation parameters
class ArtProject extends Equatable {
  /// Unique identifier for this project
  final String id;
  
  /// Project name
  final String name;
  
  /// Creation date and time
  final DateTime createdAt;
  
  /// Last modified date and time
  final DateTime modifiedAt;
  
  /// Generation parameters
  final ParameterSet parameters;
  
  /// Thumbnail image data (stored as PNG bytes)
  final Uint8List? thumbnailData;
  
  /// Optional description or notes
  final String? description;
  
  /// Tags for categorization
  final List<String> tags;
  
  /// Whether this project is marked as favorite
  final bool isFavorite;

  const ArtProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt, 
    required this.parameters,
    this.thumbnailData,
    this.description,
    this.tags = const [],
    this.isFavorite = false,
  });
  
  /// Creates a new project with default parameters
  factory ArtProject.create({
    String? name,
    ParameterSet? parameters,
    String? description,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return ArtProject(
      id: const Uuid().v4(),
      name: name ?? 'Untitled Project',
      createdAt: now,
      modifiedAt: now,
      parameters: parameters ?? ParameterSet.defaultSettings(),
      description: description,
      tags: tags ?? [],
    );
  }
  
  /// Creates a copy with updated fields
  ArtProject copyWith({
    String? name,
    DateTime? modifiedAt,
    ParameterSet? parameters,
    Uint8List? thumbnailData,
    String? description,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return ArtProject(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      parameters: parameters ?? this.parameters,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
  
  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'thumbnailData': thumbnailData?.toString(),
      'description': description,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }
  
  /// Creates from JSON
  factory ArtProject.fromJson(Map<String, dynamic> json) {
    return ArtProject(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(json['modifiedAt']),
      parameters: ParameterSet.fromJson(json['parameters']),
      thumbnailData: json['thumbnailData'] != null 
          ? Uint8List.fromList(json['thumbnailData'].codeUnits) 
          : null,
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
  
  @override
  List<Object?> get props => [
    id, 
    name, 
    createdAt, 
    modifiedAt, 
    parameters,
    description,
    tags,
    isFavorite
  ];
}