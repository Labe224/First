import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onOpenFile;
  final VoidCallback? onToggleFavorite;
  final bool isFavoriteProcessing;

  const DocumentCard({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onDelete,
    this.onOpenFile,
    this.onToggleFavorite,
    this.isFavoriteProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onToggleFavorite != null)
                    isFavoriteProcessing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : IconButton(
                            icon: Icon(
                              document.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: document.isFavorite ? theme.colorScheme.error : theme.colorScheme.outline,
                              size: 24,
                            ),
                            onPressed: onToggleFavorite,
                            tooltip: document.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                  if (onOpenFile != null && document.filePath != null && document.filePath!.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.open_in_new, color: theme.colorScheme.secondary, size: 24),
                      onPressed: onOpenFile,
                      tooltip: 'Ouvrir le fichier',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 24),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                document.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 18,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      document.category,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.map((tag) => Chip(
                    label: Text(tag),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    labelStyle: theme.chipTheme.labelStyle?.copyWith(fontSize: 12),
                  )).toList(),
                ),
              ],
              if (document.lastOpened != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      'Vu le: ${formatter.format(document.lastOpened!.toLocal())}',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 