import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'models/document.dart';
import 'screens/home_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/trash_screen.dart';
import 'screens/edit_document_screen.dart';
import 'screens/history_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire de Documents',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Document> _allDocuments = [];
  final List<String> _appBarTitles = [
    'Mes Documents',
    'Historique',
    'Assistant IA',
    'Quiz',
    'Corbeille',
  ];
  String _currentAppBarTitle = '';

  @override
  void initState() {
    super.initState();
    _allDocuments.addAll([
      Document(title: 'Rapport Annuel 2023', description: 'Un résumé complet des activités et des finances de l\'entreprise pour l\'année fiscale 2023. Inclut les bilans, les stratégies futures et les analyses de performance.', category: 'Rapports', tags: ['Finance', 'Annuel', 'Stratégie'], lastOpened: DateTime.now().subtract(const Duration(days: 1))),
      Document(title: 'Facture Client #10234', description: 'Facture détaillée pour les services de consultation fournis au client Alpha Corp en Mars. Prestations : développement web et design graphique.', category: 'Factures', tags: ['Alpha Corp', 'Consultation'], lastOpened: DateTime.now().subtract(const Duration(hours: 5))),
      Document(title: 'Contrat de Maintenance Logiciel', description: 'Contrat établissant les termes et conditions pour la maintenance continue du logiciel CRM. Valide pour une période de 2 ans.', category: 'Contrats', tags: ['Maintenance', 'CRM', 'Légal']),
      Document(title: 'Présentation Marketing Q2', description: 'Diapositives pour la présentation des résultats marketing du deuxième trimestre. Focus sur les campagnes en ligne et l\'engagement des utilisateurs.', category: 'Présentations', tags: ['Marketing', 'Q2', 'Campagne'], lastOpened: DateTime.now().subtract(const Duration(days: 3))),
    ]);
    _currentAppBarTitle = _appBarTitles[0];
  }

  void _addDocument(Document document) {
    setState(() {
      _allDocuments.insert(0, document.copyWith(lastOpened: DateTime.now()));
    });
  }

  void _updateDocument(Document oldDocument, Document newDocumentFromEditScreen) {
    setState(() {
      final index = _allDocuments.indexOf(oldDocument);
      if (index != -1) {
        print("DEBUG: Document '${oldDocument.title}' trouvé pour mise à jour.");
        _allDocuments[index] = newDocumentFromEditScreen;
      } else {
        print("DEBUG: ERREUR - Document '${oldDocument.title}' NON TROUVÉ pour mise à jour.");
      }
    });
  }

  void _toggleFavorite(Document document) {
    setState(() {
      final index = _allDocuments.indexOf(document);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        print("DEBUG: Document '${document.title}' trouvé pour basculer favori. Actuel: ${currentDocumentInList.isFavorite}");
        _allDocuments[index] = currentDocumentInList.copyWith(isFavorite: !currentDocumentInList.isFavorite);
      } else {
        print("DEBUG: ERREUR - Document '${document.title}' NON TROUVÉ pour basculer favori.");
      }
    });
  }

  void _updateLastOpened(Document document) {
    setState(() {
      final index = _allDocuments.indexOf(document);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        print("DEBUG: Document '${document.title}' trouvé pour mettre à jour lastOpened.");
        _allDocuments[index] = currentDocumentInList.copyWith(lastOpened: DateTime.now());
      } else {
        print("DEBUG: ERREUR - Document '${document.title}' NON TROUVÉ pour mettre à jour lastOpened.");
      }
    });
  }

  void _removeFromHistory(Document document) {
    setState(() {
      final index = _allDocuments.indexOf(document);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        print("DEBUG: Document '${document.title}' trouvé pour suppression de l'historique.");
        _allDocuments[index] = currentDocumentInList.copyWith(lastOpened: null);
      } else {
        print("DEBUG: ERREUR - Document '${document.title}' NON TROUVÉ pour suppression de l'historique.");
      }
    });
  }

  void _trashDocument(Document documentToTrash) {
    setState(() {
      final index = _allDocuments.indexOf(documentToTrash);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        if (!currentDocumentInList.isTrashed) {
          print("DEBUG: Document '${documentToTrash.title}' trouvé pour mise à la corbeille.");
          _allDocuments[index] = currentDocumentInList.copyWith(
            isTrashed: true,
            deletedDate: DateTime.now(),
          );
        } else {
          print("DEBUG: Document '${documentToTrash.title}' déjà dans la corbeille. Ignoré.");
        }
      } else {
        print("DEBUG: ERREUR - Document '${documentToTrash.title}' NON TROUVÉ pour mise à la corbeille.");
      }
    });
  }

  void _restoreDocument(Document documentToRestore) {
    setState(() {
      final index = _allDocuments.indexOf(documentToRestore);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        if (currentDocumentInList.isTrashed) {
          print("DEBUG: Document '${documentToRestore.title}' trouvé pour restauration.");
          _allDocuments[index] = currentDocumentInList.copyWith(
            isTrashed: false,
            deletedDate: null,
          );
        } else {
          print("DEBUG: Document '${documentToRestore.title}' n'est pas dans la corbeille. Restauration ignorée.");
        }
      } else {
        print("DEBUG: ERREUR - Document '${documentToRestore.title}' NON TROUVÉ pour restauration.");
      }
    });
  }

  void _permanentlyDeleteDocument(Document documentToDelete) {
    setState(() {
      final index = _allDocuments.indexOf(documentToDelete);
      if (index != -1) {
        final currentDocumentInList = _allDocuments[index];
        if (currentDocumentInList.isTrashed && currentDocumentInList.deletedDate != null) {
          print("DEBUG: Document '${documentToDelete.title}' trouvé pour suppression définitive.");
          _allDocuments.removeAt(index);
        } else {
          print("DEBUG: Document '${documentToDelete.title}' n'est pas (ou plus) éligible pour suppression définitive (état: isTrashed=${currentDocumentInList.isTrashed}). Suppression de la liste annulée.");
        }
      } else {
        print("DEBUG: ERREUR - Document '${documentToDelete.title}' NON TROUVÉ pour suppression définitive de la liste.");
      }
    });
  }

  Future<void> _openFile(String? filePath, Document document) async {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier attaché à ce document.')),
      );
      return;
    }
    _updateLastOpened(document);
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: ${result.message} (type: ${result.type})')),
        );
      }
    }
  }

  Future<void> _confirmTrashDocument(Document document) async {
    final bool? shouldTrash = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Mettre à la corbeille'),
          content: Text('Voulez-vous vraiment mettre le document "${document.title}" à la corbeille ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('Mettre à la corbeille', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (shouldTrash == true) {
      _trashDocument(document);
    }
  }

  Future<void> _confirmPermanentDelete(Document document) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Suppression Définitive'),
          content: Text(
              'Voulez-vous vraiment supprimer définitivement le document "${document.title}" ? Cette action est irréversible et supprimera également le fichier attaché s\'il existe.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('Supprimer Définitivement', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      if (document.filePath != null && document.filePath!.isNotEmpty) {
        try {
          final file = File(document.filePath!);
          if (await file.exists()) {
            await file.delete();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fichier "${document.fileName}" supprimé définitivement.')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de la suppression définitive du fichier: $e')),
            );
          }
        }
      }
      _permanentlyDeleteDocument(document);
    }
  }

  void _navigateToEditDocumentScreen({Document? document, required Function(Document) onSave}) {
    if (document != null) {
      _updateLastOpened(document);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDocumentScreen(
          document: document,
          onSave: onSave,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentAppBarTitle = _appBarTitles[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showFab = _selectedIndex == 0 || _selectedIndex == 1;

    final List<Widget> currentScreens = <Widget>[
      HomeScreen(
        allDocuments: _allDocuments,
        onOpenFile: (filePath, doc) => _openFile(filePath, doc),
        onTrashDocument: _confirmTrashDocument,
        onAddDocument: () => _navigateToEditDocumentScreen(onSave: _addDocument),
        onEditDocument: (doc) => _navigateToEditDocumentScreen(document: doc, onSave: (updatedDoc) => _updateDocument(doc, updatedDoc)),
        onToggleFavorite: _toggleFavorite,
        onViewDocument: _updateLastOpened,
      ),
      HistoryScreen(
        allDocuments: _allDocuments,
        onOpenFile: (filePath, doc) => _openFile(filePath, doc),
        onEditDocument: (doc) => _navigateToEditDocumentScreen(document: doc, onSave: (updatedDoc) => _updateDocument(doc, updatedDoc)),
        onViewDocument: _updateLastOpened,
        onRemoveFromHistory: _removeFromHistory,
      ),
      const AiAssistantScreen(),
      const QuizScreen(),
      TrashScreen(
        allDocuments: _allDocuments,
        onRestoreDocument: _restoreDocument,
        onPermanentlyDeleteDocument: _confirmPermanentDelete,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAppBarTitle),
      ),
      body: Center(
        child: currentScreens.elementAt(_selectedIndex),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToEditDocumentScreen(onSave: _addDocument),
              label: const Text('Ajouter'),
              icon: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_outlined),
            activeIcon: Icon(Icons.folder_copy),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant_outlined),
            activeIcon: Icon(Icons.assistant),
            label: 'Assistant IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete_outline_rounded),
            activeIcon: Icon(Icons.delete_sweep),
            label: 'Corbeille',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
