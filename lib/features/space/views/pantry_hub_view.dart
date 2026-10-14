import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/widgets/unified_resource_hub_view.dart';
import 'package:solducci/features/space/views/pantry_detail_view.dart';

/// Vista unificata per la Dispensa basata sul pattern Swipeable Chips Hub.
/// Elimina il passaggio a cartella/elenco e supporta dispense multiple (es. Casa, Mare, Ufficio).
class PantryHubView extends StatelessWidget {
  final String? initialDocumentId;

  const PantryHubView({super.key, this.initialDocumentId});

  @override
  Widget build(BuildContext context) {
    return UnifiedResourceHubView<DispensaDocument>(
      title: 'Dispensa',
      documentType: 'dispensa',
      icon: Icons.kitchen_outlined,
      accentColor: const Color(0xFF0EA5E9), // Sky Blue OLED
      showAllOption: true,
      allLabel: 'Totale',
      managementLabel: 'Dispense',
      showDensityToggle: false,
      buildAllPage: (context, allDocs, showAllNotifier) {
        if (allDocs.isEmpty) return const SizedBox.shrink();
        return PantryDetailView(
          key: const ValueKey('pantry_totale'),
          documentId: 'all',
          isAllMode: true,
          allDocuments: allDocs,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
      buildDocumentPage: (context, doc, showAllNotifier) {
        return PantryDetailView(
          key: ValueKey('pantry_${doc.id}'),
          documentId: doc.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
    );
  }
}
