import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:solducci/features/space/views/demos/demo_flip_card_view.dart';
import 'package:solducci/features/space/views/demos/demo_liquid_card_view.dart';

class InteractiveCardsShowcasePage extends StatelessWidget {
  const InteractiveCardsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: SolducciAppBar(
        title: const Text('Interactive Cards', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Soluzioni sperimentali per il rendering dei Markdown block.', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 32),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
            tileColor: const Color(0xFF1E1E2C),
            leading: const Icon(Icons.threed_rotation, color: Color(0xFF6366F1), size: 36),
            title: const Text('3D Flip Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Animazione fluida di rotazione 3D', style: TextStyle(color: Colors.white54)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DemoFlipCardView())),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
            tileColor: const Color(0xFF1E1E2C),
            leading: const Icon(Icons.waves, color: Color(0xFFE068F1), size: 36),
            title: const Text('Elastic Liquid Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Trazione elastica con bordo sinusoidale in movimento proporzionale alla velocità', style: TextStyle(color: Colors.white54)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DemoLiquidCardView())),
          ),
        ],
      ),
    );
  }
}
