import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/widgets/unified_resource_hub_view.dart';
import 'package:solducci/features/space/views/asterisk_detail_view.dart';

/// Vista unificata per gli Asterischi basata sul pattern Swipeable Chips Hub.
/// Elimina la cartella/elenco intermedia e immerge direttamente l'utente nei punti di discussione.
class AsterisksHubView extends StatelessWidget {
  final String? initialDocumentId;

  const AsterisksHubView({super.key, this.initialDocumentId});

  @override
  Widget build(BuildContext context) {
    return UnifiedResourceHubView<AsteriskDocument>(
      title: 'Asterischi',
      documentType: 'asterisk',
      initialDocumentId: initialDocumentId,
      accentColor: const Color(0xFFEAB308), // Giallo neon Solducci
      icon: Icons.emergency,
      showAllOption: false,
      managementLabel: 'Liste',
      showDensityToggle: false,
      buildDocumentPage: (context, doc, showAllNotifier) {
        return AsteriskDetailView(
          key: ValueKey('asterisk_${doc.id}'),
          documentId: doc.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
    );
  }
}
