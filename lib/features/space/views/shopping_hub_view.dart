import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/widgets/unified_resource_hub_view.dart';
import 'package:solducci/features/space/views/shopping_list_detail_view.dart';

/// Vista unificata per le Liste Spesa basata sul pattern Swipeable Chips Hub.
/// Elimina il doppio salto eliminando la pagina di passaggio cartella/elenco.
class ShoppingHubView extends StatelessWidget {
  final String? initialDocumentId;

  const ShoppingHubView({super.key, this.initialDocumentId});

  @override
  Widget build(BuildContext context) {
    return UnifiedResourceHubView<ShoppingListDocument>(
      title: 'Liste Spesa',
      documentType: 'shopping_list',
      accentColor: const Color(0xFF10B981), // Smeraldo OLED
      icon: Icons.shopping_cart_outlined,
      showAllOption: true,
      allLabel: 'Tutte',
      managementLabel: 'Liste',
      showDensityToggle: true,
      buildAllPage: (context, allDocs, showAllNotifier) {
        // Mostra la prima lista oppure un placeholder/aggregatore
        if (allDocs.isEmpty) return const SizedBox.shrink();
        return ShoppingListDetailView(
          key: const ValueKey('shopping_list_all'),
          documentId: allDocs.first.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
      buildDocumentPage: (context, doc, showAllNotifier) {
        return ShoppingListDetailView(
          key: ValueKey('shopping_list_${doc.id}'),
          documentId: doc.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
    );
  }
}
