import 'package:flutter/material.dart';
import 'package:solducci/views/documents/task_tile_design_preview.dart';
import 'package:solducci/views/documents/filter_sort_ui_preview.dart';
import 'package:solducci/views/documents/dropdown_selector_preview.dart';
import 'package:solducci/views/showcase/background_showcase_page.dart';
import 'package:solducci/views/showcase/glass_morphism_showcase_page.dart';

/// Menu page that groups all UI showcase pages
class UIShowcaseMenu extends StatelessWidget {
  const UIShowcaseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Showcase'),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildShowcaseTile(
            context: context,
            icon: Icons.palette,
            title: 'Task Card Design',
            subtitle: 'Anteprima stili delle task card',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskTileDesignPreview(),
                ),
              );
            },
          ),
          _buildShowcaseTile(
            context: context,
            icon: Icons.tune,
            title: 'Filter & Sort UI',
            subtitle: 'Showcase soluzioni filtri e ordinamento',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilterSortUIPreview(),
                ),
              );
            },
          ),
          _buildShowcaseTile(
            context: context,
            icon: Icons.arrow_drop_down_circle,
            title: 'Dropdown Selectors',
            subtitle: 'Showcase dropdown animati per filtri',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DropdownSelectorPreview(),
                ),
              );
            },
          ),
          _buildShowcaseTile(
            context: context,
            icon: Icons.gradient,
            title: 'Background Showcase',
            subtitle: 'Esplora e personalizza sfondi alternativi',
            color: Colors.deepOrange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackgroundShowcasePage(),
                ),
              );
            },
          ),
          _buildShowcaseTile(
            context: context,
            icon: Icons.blur_on,
            title: 'Glass Morphism Showcase',
            subtitle: 'Test effetti vetro e trasparenza',
            color: Colors.cyan,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlassMorphismShowcasePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
