import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:uuid/uuid.dart';
import 'models/document.dart';
import 'services/database_service.dart';
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
  final _dbService = DatabaseService.instance;
  final _uuid = Uuid();
  bool _isLoadingDocuments = true;
  Set<String> _processingFavorite = {};
  Set<String> _processingRestore = {}; // To track documents being restored
  Set<String> _processingDelete = {}; // To track documents being permanently deleted

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
    _currentAppBarTitle = _appBarTitles[0];
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    setState(() {
      _isLoadingDocuments = true;
    });

    final initialDocsData = [
      {'title': 'Rapport Annuel 2023', 'description': 'Un résumé complet des activités et des finances de l\'entreprise pour l\'année fiscale 2023. Inclut les bilans, les stratégies futures et les analyses de performance.', 'category': 'Rapports', 'tags': ['Finance', 'Annuel', 'Stratégie'], 'lastOpened': DateTime.now().subtract(const Duration(days: 1))},
      {'title': 'Facture Client #10234', 'description': 'Facture détaillée pour les services de consultation fournis au client Alpha Corp en Mars. Prestations : développement web et design graphique.', 'category': 'Factures', 'tags': ['Alpha Corp', 'Consultation'], 'lastOpened': DateTime.now().subtract(const Duration(hours: 5))},
      {'title': 'Contrat de Maintenance Logiciel', 'description': 'Contrat établissant les termes et conditions pour la maintenance continue du logiciel CRM. Valide pour une période de 2 ans.', 'category': 'Contrats', 'tags': ['Maintenance', 'CRM', 'Légal']},
      {'title': 'Présentation Marketing Q2', 'description': 'Diapositives pour la présentation des résultats marketing du deuxième trimestre. Focus sur les campagnes en ligne et l\'engagement des utilisateurs.', 'category': 'Présentations', 'tags': ['Marketing', 'Q2', 'Campagne'], 'lastOpened': DateTime.now().subtract(const Duration(days: 3))},
    ];

    for (var docData in initialDocsData) {
      final doc = Document(
        id: _uuid.v4(),
        title: docData['title'] as String,
        description: docData['description'] as String,
        category: docData['category'] as String,
        tags: docData['tags'] as List<String>,
        lastOpened: docData['lastOpened'] as DateTime?,
        // Ensure other fields like filePath, fileName, isTrashed, etc., are initialized if needed
        filePath: null, 
        fileName: null,
        isTrashed: false,
        deletedDate: null,
        isFavorite: false, 
      );
      try {
        await _dbService.insertDocument(doc);
      } catch (e) {
        print("Erreur lors de l'insertion du document initial ${doc.title}: $e");
      }
    }

    try {
      List<Document> fetchedDocs = await _dbService.getAllDocuments();
      setState(() {
        _allDocuments.clear();
        _allDocuments.addAll(fetchedDocs);
      });
    } catch (e) {
      print("Erreur lors de la récupération des documents: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des documents: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingDocuments = false;
      });
    }
  }

  void _addDocument(Document document) {
    // This method will be updated to use DB service.
    // For now, it adds to local list for UI responsiveness.
    // Actual save should happen via EditDocumentScreen calling a DB save method.
    final newDocWithId = document.copyWith(id: _uuid.v4(), lastOpened: DateTime.now());
    _dbService.insertDocument(newDocWithId).then((_) {
      setState(() {
        _allDocuments.insert(0, newDocWithId);
      });
    }).catchError((e) {
       print("Erreur lors de l'ajout du document: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erreur d\'ajout du document: $e')),
         );
       }
    });
  }

  void _updateDocument(Document oldDocument, Document newDocumentFromEditScreen) {
    _dbService.updateDocument(newDocumentFromEditScreen).then((_) {
      setState(() {
        final index = _allDocuments.indexWhere((d) => d.id == oldDocument.id);
        if (index != -1) {
          _allDocuments[index] = newDocumentFromEditScreen;
        } else {
           print("DEBUG: ERREUR - Document '${oldDocument.title}' (ID: ${oldDocument.id}) NON TROUVÉ pour mise à jour après sauvegarde DB.");
        }
      });
    }).catchError((e) {
      print("Erreur lors de la mise à jour du document ${oldDocument.title}: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de mise à jour du document: $e')),
        );
      }
    });
  }

  // Original Problem: Synchronous, updated only in-memory list, no DB interaction or specific UI loading feedback.
  // Solution: Now asynchronous, persists to DatabaseService, updates local state by ID, manages per-item loading UI.
  //
  // Toggles the favorite status of a document.
  // This method is asynchronous as it involves updating the database.
  Future<void> _toggleFavorite(Document document) async {
    // Prevent multiple simultaneous toggles for the same document.
    if (_processingFavorite.contains(document.id)) {
      return; 
    }

    // Add document ID to the processing set to indicate loading for this item's favorite button.
    // setState is called to rebuild the UI and show a loading indicator on the DocumentCard.
    setState(() {
      _processingFavorite.add(document.id);
    });

    // Create an updated version of the document with the toggled favorite status.
    final updatedDocument = document.copyWith(isFavorite: !document.isFavorite);

    try {
      // Attempt to update the document in the database.
      await _dbService.updateDocument(updatedDocument);

      // If the database update is successful, update the document in the local list.
      // setState is called here to ensure the UI reflects the change immediately after DB confirmation.
      setState(() {
        // Find the document by its unique ID.
        final index = _allDocuments.indexWhere((d) => d.id == updatedDocument.id);
        if (index != -1) {
          _allDocuments[index] = updatedDocument;
        }
      });
    } catch (e) {
      // If an error occurs during the database operation, print the error and show a SnackBar.
      print("Erreur lors de la mise à jour du favori pour ${document.title}: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de mise à jour du favori: $e')),
        );
      }
      // Optionally, re-throw the error if higher-level handling is needed or if you want to
      // revert optimistic UI changes (though current setup updates UI after DB success).
    } finally {
      // Always remove the document ID from the processing set,
      // whether the operation succeeded or failed, to ensure the loading indicator is removed.
      // setState is called to rebuild the UI and remove the loading indicator.
      setState(() {
        _processingFavorite.remove(document.id);
      });
    }
  }

  void _updateLastOpened(Document document) {
    final updatedDocument = document.copyWith(lastOpened: DateTime.now());
    _dbService.updateDocument(updatedDocument).then((_) {
      setState(() {
        final index = _allDocuments.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          _allDocuments[index] = updatedDocument;
        }
      });
    }).catchError((e) {
       print("Erreur lors de la mise à jour de lastOpened pour ${document.title}: $e");
    });
  }

  void _removeFromHistory(Document document) {
    final updatedDocument = document.copyWith(lastOpened: null);
     _dbService.updateDocument(updatedDocument).then((_) {
        setState(() {
          final index = _allDocuments.indexWhere((d) => d.id == document.id);
          if (index != -1) {
            _allDocuments[index] = updatedDocument;
          }
        });
    }).catchError((e) {
       print("Erreur lors de la suppression de l'historique pour ${document.title}: $e");
    });
  }

  // Original Problem: Synchronous operation, only updated an in-memory list (setting flags), no database interaction to persist the trashed state.
  // Solution: Made asynchronous, interacts with DatabaseService to mark document as trashed and set deletedDate, updates local state by ID. UI feedback handled by _confirmTrashDocument dialog.
  //
  // Marks a document as trashed and updates its deletedDate.
  // This method is asynchronous as it involves updating the database.
  Future<void> _trashDocument(Document documentToTrash) async {
    // Create an updated version of the document marked as trashed with the current date.
    final updatedDocument = documentToTrash.copyWith(
      isTrashed: true,
      deletedDate: DateTime.now(),
    );

    try {
      // Attempt to update the document in the database.
      await _dbService.updateDocument(updatedDocument);

      // If the database update is successful, update the document in the local list.
      // setState is called to rebuild the UI. In HomeScreen, this document will
      // be filtered out from the main list as it's now marked as trashed.
      setState(() {
        // Find the document by its unique ID.
        final index = _allDocuments.indexWhere((d) => d.id == updatedDocument.id);
        if (index != -1) {
          _allDocuments[index] = updatedDocument;
        }
      });
    } catch (e) {
      // If an error occurs during the database operation, print the error and show a SnackBar.
      print("Erreur lors de la mise à la corbeille de ${documentToTrash.title}: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à la corbeille: $e')),
        );
      }
      // Optionally, re-throw the error if higher-level handling is needed.
    }
  }

  // Original Problem: Synchronous operation, only updated an in-memory list (resetting flags), no database interaction to persist restoration.
  // Solution: Made asynchronous, interacts with DatabaseService to unmark document as trashed and clear deletedDate, updates local state by ID, and manages a per-item loading indicator in TrashScreen.
  //
  // Restores a document from the trash.
  // This method is asynchronous due to database interaction.
  Future<void> _restoreDocument(Document documentToRestore) async {
    // Add document ID to the processing set to indicate loading for this item.
    // This will be used by TrashScreen to show a loading indicator on the specific document card.
    setState(() {
      _processingRestore.add(documentToRestore.id);
    });

    // Create an updated version of the document with isTrashed set to false and deletedDate to null.
    final updatedDocument = documentToRestore.copyWith(
      isTrashed: false,
      deletedDate: null, // Ensure copyWith handles setting nullable fields to null
    );

    try {
      // Attempt to update the document in the database.
      await _dbService.updateDocument(updatedDocument);

      // If the database update is successful, update the document in the local list.
      // setState is called here to ensure the UI reflects the change immediately.
      // The document will now reappear in the main documents list (HomeScreen)
      // and disappear from the TrashScreen.
      setState(() {
        // Find the document by its unique ID.
        final index = _allDocuments.indexWhere((d) => d.id == updatedDocument.id);
        if (index != -1) {
          _allDocuments[index] = updatedDocument;
        }
        // No need to remove from a separate trash list if _allDocuments is the single source of truth.
        // Filtering in HomeScreen and TrashScreen will handle visibility.
      });
    } catch (e) {
      // If an error occurs during the database operation, print the error and show a SnackBar.
      print("Erreur lors de la restauration de ${documentToRestore.title}: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la restauration: $e')),
        );
      }
      // Optionally, re-throw the error or handle UI reversion if an optimistic update was performed.
    } finally {
      // Always remove the document ID from the processing set,
      // whether the operation succeeded or failed, to ensure the loading indicator is removed.
      // setState is called to rebuild the UI (specifically TrashScreen in this context).
      setState(() {
        _processingRestore.remove(documentToRestore.id);
      });
    }
  }

  // Original Problem: Synchronous operation, only removed document from an in-memory list, no database interaction for permanent deletion.
  // Solution: Made asynchronous, interacts with DatabaseService to delete the document record, removes from local list by ID. UI feedback handled by _confirmPermanentDelete dialog and potentially per-item indicators in TrashScreen.
  //
  // Permanently deletes a document from the database and the local list.
  // This method is asynchronous due to database interaction.
  Future<void> _permanentlyDeleteDocument(Document documentToDelete) async {
    // Add document ID to the processing set to indicate loading for this item.
    // This will be used by TrashScreen to show a loading indicator on the specific document card.
    setState(() {
      _processingDelete.add(documentToDelete.id);
    });

    try {
      // Attempt to delete the document from the database.
      await _dbService.deleteDocument(documentToDelete.id);

      // If the database deletion is successful, remove the document from the local list.
      // setState is called here to ensure the UI reflects the change immediately.
      // The document will be removed from the TrashScreen.
      setState(() {
        _allDocuments.removeWhere((d) => d.id == documentToDelete.id);
      });
    } catch (e) {
      // If an error occurs during the database operation, print the error and show a SnackBar.
      // Note: At this point, the associated file (if any) might have already been deleted
      // by _confirmPermanentDelete. This could lead to an inconsistent state.
      // For now, we just show an error message.
      print("Erreur lors de la suppression définitive de la base de données pour ${documentToDelete.title}: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression définitive de la base de données: $e')),
        );
      }
      // More advanced error handling might involve trying to re-insert a record,
      // or logging this inconsistency for manual review.
    } finally {
      // Always remove the document ID from the processing set,
      // whether the operation succeeded or failed, to ensure the loading indicator is removed.
      // setState is called to rebuild the UI (specifically TrashScreen).
      setState(() {
        _processingDelete.remove(documentToDelete.id);
      });
    }
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

  // Displays a confirmation dialog before moving a document to the trash.
  // If confirmed, it calls the asynchronous _trashDocument method.
  Future<void> _confirmTrashDocument(Document document) async {
    bool isTrashing = false; // Local state for dialog's loading indicator

    final bool? shouldTrash = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the loading state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Mettre à la corbeille'),
              content: Text('Voulez-vous vraiment mettre le document "${document.title}" à la corbeille ?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  // Disable button if trashing is in progress
                  onPressed: isTrashing ? null : () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: isTrashing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Mettre à la corbeille', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  // Disable button if trashing is in progress
                  onPressed: isTrashing ? null : () async {
                    setDialogState(() {
                      isTrashing = true; // Show loading indicator
                    });
                    // Perform the async operation
                    await _trashDocument(document); 
                    // Close dialog only after operation is complete
                    if (mounted) Navigator.of(dialogContext).pop(true); 
                  },
                ),
              ],
            );
          }
        );
      },
    );
    // Note: The actual trashing and UI update is handled by _trashDocument.
    // The shouldTrash boolean from the dialog is now primarily for knowing if the user confirmed.
    // If we needed to do something specific *after* trashing based on dialog confirmation (e.g. analytics),
    // we could use the result of pop(true).
  }

  // Displays a confirmation dialog before permanently deleting a document.
  // Handles file deletion (if applicable) and then calls _permanentlyDeleteDocument for database and list removal.
  // Manages a loading state for the dialog's delete button.
  Future<void> _confirmPermanentDelete(Document document) async {
    bool isDeletingWithFileDialog = false; // Local state for dialog's loading indicator

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to manage dialog's internal state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Suppression Définitive'),
              content: Text(
                  'Voulez-vous vraiment supprimer définitivement le document "${document.title}" ? Cette action est irréversible et supprimera également le fichier attaché s\'il existe.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  // Disable button if deleting is in progress
                  onPressed: isDeletingWithFileDialog ? null : () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: isDeletingWithFileDialog
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Supprimer Définitivement', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  // Disable button if deleting is in progress
                  onPressed: isDeletingWithFileDialog ? null : () async {
                    setDialogState(() {
                      isDeletingWithFileDialog = true; // Show loading indicator
                    });
                    
                    try {
                      // First, attempt to delete the associated file if it exists.
                      if (document.filePath != null && document.filePath!.isNotEmpty) {
                        try {
                          final file = File(document.filePath!);
                          if (await file.exists()) {
                            await file.delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fichier "${document.fileName}" supprimé.')),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors de la suppression du fichier: $e')),
                            );
                          }
                          // Depending on policy, you might choose to not proceed with DB deletion if file deletion fails.
                          // For now, we'll proceed.
                        }
                      }
                      // After file deletion (or if no file), proceed to delete from database and local list.
                      await _permanentlyDeleteDocument(document);
                    } finally {
                      // Ensure loading state is reset and dialog is closed, regardless of outcome.
                      // No need to call setDialogState for isDeletingWithFileDialog here as the dialog will be popped.
                      if (mounted) Navigator.of(dialogContext).pop(true); // Close dialog indicating delete was attempted/confirmed
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
    // 'shouldDelete' is true if the dialog was popped by pressing the "Supprimer Définitivement" button's logic.
    // No further action needed here as _permanentlyDeleteDocument handles UI updates.
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

    Widget bodyContent;
    if (_isLoadingDocuments) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else {
      final List<Widget> currentScreens = <Widget>[
        HomeScreen(
          allDocuments: _allDocuments,
          onOpenFile: (filePath, doc) => _openFile(filePath, doc),
          onTrashDocument: _confirmTrashDocument,
          onAddDocument: () => _navigateToEditDocumentScreen(onSave: _addDocument),
          onEditDocument: (doc) => _navigateToEditDocumentScreen(document: doc, onSave: (updatedDoc) => _updateDocument(doc, updatedDoc)),
          onToggleFavorite: _toggleFavorite,
          onViewDocument: _updateLastOpened,
          processingFavoriteIds: _processingFavorite, // Pass this down
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
          processingRestoreIds: _processingRestore, 
          processingDeleteIds: _processingDelete, // Pass the set for delete loading indicators
        ),
      ];
      bodyContent = currentScreens.elementAt(_selectedIndex);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAppBarTitle),
      ),
      body: Center(
        child: bodyContent,
      ),
      floatingActionButton: showFab && !_isLoadingDocuments
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
