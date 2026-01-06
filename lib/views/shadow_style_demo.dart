import 'package:flutter/material.dart';

/// Demo page per testare i tre stili di ombreggiatura/evidenziazione
/// per i chip correlati (vista ↔ gruppi)
class ShadowStyleDemoPage extends StatelessWidget {
  const ShadowStyleDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Stili Ombreggiatura'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Scegli lo stile di evidenziazione per i chip correlati',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Questi stili vengono applicati quando selezioni una vista (evidenzia i gruppi) o multi-selezioni gruppi di una vista (evidenzia la vista)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Opzione A: Bordo Colorato
          _buildSection(
            'Opzione A: Bordo Colorato',
            'Bordo blu spesso intorno al chip',
            [
              _buildChip('Gruppo Normale', isSelected: false, styleType: null),
              _buildChip('Gruppo Selezionato', isSelected: true, styleType: null),
              _buildChip('Gruppo Correlato', isSelected: false, styleType: 'border'),
            ],
          ),

          const SizedBox(height: 32),

          // Opzione B: Background Semi-trasparente
          _buildSection(
            'Opzione B: Background Semi-trasparente',
            'Background blu chiaro con opacity',
            [
              _buildChip('Gruppo Normale', isSelected: false, styleType: null),
              _buildChip('Gruppo Selezionato', isSelected: true, styleType: null),
              _buildChip('Gruppo Correlato', isSelected: false, styleType: 'background'),
            ],
          ),

          const SizedBox(height: 32),

          // Opzione C: Glow Effect
          _buildSection(
            'Opzione C: Glow Effect',
            'Effetto glow con BoxShadow colorata',
            [
              _buildChip('Gruppo Normale', isSelected: false, styleType: null),
              _buildChip('Gruppo Selezionato', isSelected: true, styleType: null),
              _buildChip('Gruppo Correlato', isSelected: false, styleType: 'glow'),
            ],
          ),

          const SizedBox(height: 32),

          const Divider(),
          const SizedBox(height: 16),

          // Comparazione side-by-side
          const Text(
            'Comparazione',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                children: [
                  _buildChip('Bordo', isSelected: false, styleType: 'border'),
                  const SizedBox(height: 4),
                  const Text('A', style: TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                children: [
                  _buildChip('Background', isSelected: false, styleType: 'background'),
                  const SizedBox(height: 4),
                  const Text('B', style: TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                children: [
                  _buildChip('Glow', isSelected: false, styleType: 'glow'),
                  const SizedBox(height: 4),
                  const Text('C', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildChip(String label, {required bool isSelected, String? styleType}) {
    // Colori base
    final baseColor = isSelected ? Colors.blue[700]! : Colors.grey[300]!;
    final bgColor = isSelected ? Colors.blue[700]! : Colors.grey[100]!;
    final textColor = isSelected ? Colors.white : Colors.black87;

    // Stili per stato "correlato"
    BoxDecoration decoration;

    if (styleType == null) {
      // Stato normale o selezionato
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor, width: isSelected ? 2 : 1),
      );
    } else if (styleType == 'border') {
      // Opzione A: Bordo colorato spesso
      decoration = BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[400]!, width: 3),
      );
    } else if (styleType == 'background') {
      // Opzione B: Background semi-trasparente
      decoration = BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      );
    } else {
      // Opzione C: Glow effect
      decoration = BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[300]!.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      );
    }

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group,
            size: 18,
            color: styleType != null ? Colors.blue[700] : textColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: styleType != null ? Colors.blue[700] : textColor,
              fontWeight: styleType != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
