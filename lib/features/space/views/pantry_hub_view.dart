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
      accentColor: const Color(0xFF0EA5E9), // Sky Blue OLED
      icon: Icons.kitchen_outlined,
      showAllOption: false,
      managementLabel: 'Dispense',
      showDensityToggle: false,
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
