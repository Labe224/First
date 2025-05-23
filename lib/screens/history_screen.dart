import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import '../widgets/document_card.dart'; // Peut-être réutiliser ou adapter

typedef DocumentCallback = void Function(Document document);
typedef OpenFileWithDocCallback = Future<void> Function(String? filePath, Document document);

class HistoryScreen extends StatelessWidget {
  final List<Document> allDocuments;
  final OpenFileWithDocCallback onOpenFile;
  final DocumentCallback onEditDocument; // Pour naviguer vers l'édition
  final DocumentCallback onViewDocument; // Pour mettre à jour lastOpened si on clique juste pour voir
  final DocumentCallback onRemoveFromHistory; // Nouvelle callback

  const HistoryScreen({
    Key? key,
    required this.allDocuments,
    required this.onOpenFile,
    required this.onEditDocument,
    required this.onViewDocument,
    required this.onRemoveFromHistory, // Ajouter ici
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

    // Filtrer les documents qui ont été ouverts et les trier
    List<Document> historyDocuments = allDocuments
        .where((doc) => doc.lastOpened != null && !doc.isTrashed)
        .toList();
    historyDocuments.sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!)); // Plus récent en premier

    return Scaffold(
      body: historyDocuments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun document consulté récemment.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: historyDocuments.length,
              itemBuilder: (context, index) {
                final document = historyDocuments[index];
                return Card(
                  key: ValueKey(document),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      document.isFavorite ? Icons.favorite : Icons.description_outlined,
                      color: document.isFavorite ? theme.colorScheme.error : theme.colorScheme.secondary,
                    ),
                    title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'Consulté le: ${formatter.format(document.lastOpened!.toLocal())}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error.withOpacity(0.7)),
                          onPressed: () => onRemoveFromHistory(document),
                          tooltip: 'Retirer de l\'historique',
                        ),
                        if (document.filePath != null && document.filePath!.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.open_in_new, color: theme.colorScheme.tertiary),
                            onPressed: () => onOpenFile(document.filePath, document),
                            tooltip: 'Ouvrir le fichier',
                          ),
                        IconButton(
                          icon: Icon(Icons.edit_note, color: theme.colorScheme.primary),
                          onPressed: () {
                             onEditDocument(document);
                          },
                          tooltip: 'Voir/Modifier les détails',
                        ),
                      ],
                    ),
                    onTap: () {
                      onEditDocument(document);
                    },
                  ),
                );
              },
            ),
    );
  }
} 