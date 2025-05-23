import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import '../models/document.dart';

class EditDocumentScreen extends StatefulWidget {
  final Document? document;
  final Function(Document) onSave;

  const EditDocumentScreen({Key? key, this.document, required this.onSave}) : super(key: key);

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController; // Pour gérer les tags comme une chaîne séparée par des virgules
  String? _pickedFilePath; // conserver pour l'affichage du nom
  String? _pickedFileName; // conserver pour l'affichage du nom
  bool _isFavorite = false; // Pour gérer l'état de favori
  DateTime? _lastOpened; // Pour conserver la date de dernière ouverture

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document?.title ?? '');
    _descriptionController = TextEditingController(text: widget.document?.description ?? '');
    _categoryController = TextEditingController(text: widget.document?.category ?? '');
    _tagsController = TextEditingController(text: widget.document?.tags.join(', ') ?? '');
    _pickedFilePath = widget.document?.filePath; // Restaurer le chemin si le document est existant
    _pickedFileName = widget.document?.fileName; // Restaurer le nom si le document est existant
    _isFavorite = widget.document?.isFavorite ?? false; // Restaurer l'état de favori
    _lastOpened = widget.document?.lastOpened; // Restaurer la date de dernière ouverture
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Permettre tous les types de fichiers
        // allowedExtensions: ['txt'], // Supprimé pour permettre tous les fichiers
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Obtenir le répertoire des documents de l'application
        final appDocsDir = await getApplicationDocumentsDirectory();
        final localAppDocsPath = appDocsDir.path;
        
        // Créer un sous-répertoire 'documents_storage' s'il n'existe pas
        final documentsStorageDir = Directory(p.join(localAppDocsPath, 'documents_storage'));
        if (!await documentsStorageDir.exists()) {
          await documentsStorageDir.create(recursive: true);
        }

        // Définir le chemin de destination pour le fichier copié
        final newFilePath = p.join(documentsStorageDir.path, fileName);
        
        // Supprimer l'ancien fichier si un nouveau est choisi (et qu'un ancien existait)
        if (_pickedFilePath != null && _pickedFilePath != newFilePath) {
          final oldFile = File(_pickedFilePath!);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
            } catch (e) {
              // Gérer l'erreur de suppression si nécessaire
            }
          }
        }
        
        // Copier le fichier
        await File(sourcePath).copy(newFilePath);

        setState(() {
          _pickedFilePath = newFilePath; // Stocker le chemin du fichier copié dans l'app
          _pickedFileName = fileName;
        });

        // // Ne plus lire le contenu dans la description automatiquement
        // if (fileName.toLowerCase().endsWith('.txt')) {
        //   final file = File(newFilePath); // Lire depuis la copie
        //   try {
        //     final content = await file.readAsString();
        //     _descriptionController.text = content;
        //   } catch (e) {
        //     if (mounted) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(content: Text('Erreur lors de la lecture du contenu du fichier: $e')),
        //       );
        //     }
        //   }
        // }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fichier "$_pickedFileName" sélectionné et sauvegardé dans l\'application.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun fichier sélectionné.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection ou sauvegarde du fichier: $e')),
        );
      }
    }
  }

  Future<void> _removeFile() async { // Doit être async pour la suppression de fichier
    if (_pickedFilePath != null) {
      try {
        final fileToDelete = File(_pickedFilePath!);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression du fichier local: $e')),
          );
        }
      }
    }
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier retiré de la sélection et de l\'application.')),
      );
    }
  }

  Future<void> _openFile(String? filePath) async {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun chemin de fichier disponible pour l\'ouverture.')),
      );
      return;
    }
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: ${result.message} (type: ${result.type})')),
        );
      }
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      final newDocument = Document(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        tags: tags,
        filePath: _pickedFilePath,
        fileName: _pickedFileName,
        isFavorite: _isFavorite, // Sauvegarder l'état de favori
        lastOpened: _lastOpened, // Sauvegarder la date de dernière ouverture
        // isTrashed et deletedDate ne sont pas gérés ici, ils sont gérés par MainScreen
      );
      widget.onSave(newDocument);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'Nouveau Document' : 'Modifier le Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Enregistrer',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              SwitchListTile(
                title: const Text('Marquer comme favori'),
                value: _isFavorite,
                onChanged: (bool value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
                secondary: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: theme.colorScheme.error),
                activeColor: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  icon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description/Contenu',
                  alignLabelWithHint: true,
                  icon: Icon(Icons.description_outlined),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description ou un contenu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Fichier attaché', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_pickedFileName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedFileName!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton( // Ajout du bouton Ouvrir
                        icon: Icon(Icons.open_in_new, color: Theme.of(context).colorScheme.secondary),
                        onPressed: () => _openFile(_pickedFilePath),
                        tooltip: 'Ouvrir le fichier',
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                        onPressed: _removeFile,
                        tooltip: 'Retirer le fichier',
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Aucun fichier attaché.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file_outlined),
                label: const Text('Attacher un fichier'), // Texte générique
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40), // Largeur complète
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  icon: Icon(Icons.category_outlined),
                ),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (séparés par une virgule)',
                  icon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer le Document'),
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 