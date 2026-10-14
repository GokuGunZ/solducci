import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/widgets/unified_resource_hub_view.dart';
import 'package:solducci/features/space/views/note_detail_view.dart';

/// Vista unificata per le Note basata sul pattern Swipeable Chips Hub.
/// Elimina il doppio salto eliminando la schermata cartella/elenco.
class NotesHubView extends StatelessWidget {
  final String? initialDocumentId;

  const NotesHubView({super.key, this.initialDocumentId});

  @override
  Widget build(BuildContext context) {
    return UnifiedResourceHubView<NoteDocument>(
      title: 'Note',
      documentType: 'note',
      accentColor: const Color(0xFFF59E0B), // Ambra neon Solducci
      icon: Icons.note_alt_outlined,
      showAllOption: false,
      managementLabel: 'Note',
      showDensityToggle: true,
      buildDocumentPage: (context, doc, showAllNotifier) {
        return NoteDetailView(
          key: ValueKey('note_${doc.id}'),
          documentId: doc.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
    );
  }
}
