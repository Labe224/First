import 'package:uuid/uuid.dart';

class Document {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String? filePath; // Chemin du fichier attaché
  final String? fileName; // Nom du fichier attaché
  bool isTrashed;         // Nouveau champ
  DateTime? deletedDate;  // Nouveau champ
  bool isFavorite;      // Champ pour les favoris
  DateTime? lastOpened;   // Champ pour l'historique de consultation

  Document({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    this.filePath,
    this.fileName,
    this.isTrashed = false, // Valeur par défaut
    this.deletedDate,
    this.isFavorite = false, // Valeur par défaut
    this.lastOpened,
  });

  Document copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? filePath,
    String? fileName,
    bool? isTrashed,
    DateTime? deletedDate,
    bool? isFavorite,
    DateTime? lastOpened,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      isTrashed: isTrashed ?? this.isTrashed,
      deletedDate: deletedDate ?? this.deletedDate,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'filePath': filePath,
      'fileName': fileName,
      'isTrashed': isTrashed,
      'deletedDate': deletedDate?.toIso8601String(),
      'isFavorite': isFavorite,
      'lastOpened': lastOpened?.toIso8601String(),
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      tags: List<String>.from(json['tags']),
      filePath: json['filePath'],
      fileName: json['fileName'],
      isTrashed: json['isTrashed'] ?? false,
      deletedDate: json['deletedDate'] != null
          ? DateTime.parse(json['deletedDate'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'])
          : null,
    );
  }
} 