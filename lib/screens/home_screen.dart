import 'package:flutter/material.dart';
// import 'package:open_filex/open_filex.dart'; // Plus géré ici directement
import '../models/document.dart';
import '../widgets/document_card.dart';
// import 'edit_document_screen.dart'; // La navigation est gérée par MainScreen
// import 'trash_screen.dart'; // Plus de navigation directe vers TrashScreen d'ici
// import 'dart:io'; // Plus géré ici directement

// Callbacks définies pour correspondre à ce que MainScreenState fournira
typedef DocumentCallback = void Function(Document document);
// typedef OpenFileCallback = Future<void> Function(String? filePath);
// Correction du type pour correspondre à l'usage, et ajout du Document
typedef OpenFileWithDocCallback = Future<void> Function(String? filePath, Document document); 
// typedef NavigateToEditDocumentCallback = void Function({Document? document});
// Simplification de la callback onEditDocument pour prendre directement le document.
// La navigation elle-même est gérée dans MainScreenState.

class HomeScreen extends StatefulWidget {
  final List<Document> allDocuments; // Reçu de MainScreen
  final OpenFileWithDocCallback onOpenFile; // Mise à jour du type
  final DocumentCallback onTrashDocument;
  final VoidCallback onAddDocument; // Pour naviguer vers EditScreen (via MainScreen)
  final DocumentCallback onEditDocument; // Prend un Document
  final DocumentCallback onToggleFavorite; // Nouveau
  final DocumentCallback onViewDocument;   // Nouveau (pour mettre à jour lastOpened en tapant sur la carte)
  final Set<String> processingFavoriteIds; // Ajout pour l'indicateur de chargement
  
  const HomeScreen({
    Key? key,
    required this.allDocuments,
    required this.onOpenFile,
    required this.onTrashDocument,
    required this.onAddDocument,
    required this.onEditDocument,
    required this.onToggleFavorite, // Ajouter
    required this.onViewDocument,   // Ajouter
    required this.processingFavoriteIds, // Ajout pour l'indicateur de chargement
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final List<Document> _documents = []; // Géré par MainScreen maintenant
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  // initState n'initialise plus _documents
  // @override
  // void initState() {
  //   super.initState();
  // }

  List<Document> get _filteredDocuments {
    return widget.allDocuments.where((doc) { // Utilise widget.allDocuments
      if (doc.isTrashed) return false;
      final matchesSearch = _searchQuery.isEmpty || 
                            doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            doc.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (doc.fileName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategory == 'Tous' || doc.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Les fonctions _addDocument, _updateDocument, _trashDocument, etc. sont maintenant dans MainScreenState
  // _openFile est aussi dans MainScreenState et passé via widget.onOpenFile

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculer la liste filtrée une seule fois au début de la méthode build.
    final List<Document> currentFilteredDocuments = _filteredDocuments;

    return Column( // HomeScreen retourne maintenant directement son contenu, pas un Scaffold entier
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre, description ou nom de fichier...', // Mise à jour du hint
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Filtrer par catégorie:', style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: theme.colorScheme.surface,
                    items: ['Tous', 'Rapports', 'Factures', 'Contrats', 'Présentations', 'Autres']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    underline: Container(
                      height: 1,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    icon: Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: currentFilteredDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.find_in_page_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != 'Tous' 
                          ? 'Aucun document ne correspond\nà vos critères de recherche.'
                          : 'Aucun document pour le moment.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      if (_searchQuery.isEmpty && _selectedCategory == 'Tous') ...[
                         const SizedBox(height: 20),
                         ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Ajouter un document'),
                          onPressed: widget.onAddDocument,
                         )
                      ]
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Pour éviter le chevauchement avec le FAB
                  itemCount: currentFilteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = currentFilteredDocuments[index];
                    return DocumentCard(
                      key: ValueKey(document),
                      document: document,
                      onTap: () {
                        widget.onViewDocument(document); // Mettre à jour lastOpened
                        widget.onEditDocument(document); // Puis naviguer
                      },
                      onOpenFile: () => widget.onOpenFile(document.filePath, document), // Passer le document
                      onDelete: () => widget.onTrashDocument(document),
                      onToggleFavorite: () => widget.onToggleFavorite(document), // Connecter la callback
                      isFavoriteProcessing: widget.processingFavoriteIds.contains(document.id), // Passer l'état de chargement
                    );
                  },
                ),
        ),
      ],
    );
  }

  // _navigateToAddDocumentScreen est géré par MainScreenState
  // _confirmTrashDocument est géré par MainScreenState
  // _confirmPermanentDelete est géré par MainScreenState

  // Si HomeScreen doit rester un Scaffold, il faut ajuster la structure dans MainScreen.
  // Pour l'instant, je le transforme en un Column pour qu'il s'intègre dans le body de MainScreen.
}

// Pour que HomeScreen soit un Scaffold indépendant, il faudrait le lancer différemment depuis MainScreen
// et ne pas l'imbriquer dans le Center/body du Scaffold de MainScreen.
// Mais pour une intégration avec BottomNavigationBar, la structure actuelle (HomeScreen comme contenu) est courante. 