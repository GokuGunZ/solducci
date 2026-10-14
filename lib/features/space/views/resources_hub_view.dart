import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/features/space/widgets/unified_resource_hub_view.dart';
import 'package:solducci/features/space/views/resource_detail_view.dart';

/// Vista unificata per le Risorse (link, documenti, bookmark) basata sul pattern Swipeable Chips Hub.
class ResourcesHubView extends StatelessWidget {
  final String? initialDocumentId;

  const ResourcesHubView({super.key, this.initialDocumentId});

  @override
  Widget build(BuildContext context) {
    return UnifiedResourceHubView<ResourceListDocument>(
      title: 'Risorse',
      documentType: 'resource_list',
      accentColor: const Color(0xFF3B82F6), // Deep Sky Blue OLED
      icon: Icons.bookmark_border_rounded,
      showAllOption: false,
      managementLabel: 'Raccolte',
      showDensityToggle: true,
      buildDocumentPage: (context, doc, showAllNotifier) {
        return ResourceDetailView(
          key: ValueKey('resource_${doc.id}'),
          documentId: doc.id,
          isEmbeddedMode: true,
          showAllPropertiesNotifier: showAllNotifier,
        );
      },
    );
  }
}
