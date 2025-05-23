import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/document.dart';
import '../widgets/document_card.dart'; // Nous pourrions réutiliser DocumentCard ou créer une version adaptée

typedef OnDocumentAction = void Function(Document document);

class TrashScreen extends StatelessWidget {
  final List<Document> allDocuments; // La liste complète de tous les documents
  final OnDocumentAction onRestoreDocument;
  final OnDocumentAction onPermanentlyDeleteDocument;
  final Set<String> processingRestoreIds;
  final Set<String> processingDeleteIds;

  const TrashScreen({
    Key? key,
    required this.allDocuments,
    required this.onRestoreDocument,
    required this.onPermanentlyDeleteDocument,
    required this.processingRestoreIds,
    required this.processingDeleteIds,
  }) : super(key: key);

  List<Document> get _trashedDocuments => allDocuments.where((doc) => doc.isTrashed).toList();

  Future<void> _openFile(BuildContext context, String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier attaché à ce document.')),
      );
      return;
    }
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: ${result.message} (type: ${result.type})')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trashedDocs = _trashedDocuments;

    return Scaffold(
      body: trashedDocs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'La corbeille est vide.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: trashedDocs.length,
              itemBuilder: (context, index) {
                final document = trashedDocs[index];
                return Card(
                  key: ValueKey(document),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'Supprimé le: ${document.deletedDate?.toLocal().toString().substring(0, 16) ?? 'Date inconnue'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    leading: Icon(Icons.description_outlined, color: theme.colorScheme.secondary),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (document.filePath != null && document.filePath!.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.open_in_new, color: theme.colorScheme.tertiary),
                            onPressed: () => _openFile(context, document.filePath),
                            tooltip: 'Ouvrir le fichier',
                          ),
                        widget.processingRestoreIds.contains(document.id)
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0))
                            : IconButton(
                                icon: Icon(Icons.restore_from_trash, color: theme.colorScheme.primary),
                                onPressed: () => onRestoreDocument(document),
                                tooltip: 'Restaurer',
                              ),
                        widget.processingDeleteIds.contains(document.id)
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0))
                            : IconButton(
                                icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                                onPressed: () => onPermanentlyDeleteDocument(document),
                                tooltip: 'Supprimer définitivement',
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 