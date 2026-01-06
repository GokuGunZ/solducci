import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder page for notes and lists
/// Now redirects to the new ToDo Lists feature
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note & Liste'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 120,
                color: Colors.purple[300],
              ),
              const SizedBox(height: 32),
              Text(
                'ToDo Lists',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gestisci le tue task e progetti',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem('Task con sub-task', Icons.list),
                    _buildFeatureItem('Tag e categorie', Icons.label),
                    _buildFeatureItem('Task ricorrenti', Icons.repeat),
                    _buildFeatureItem('Priorità e scadenze', Icons.flag),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // NEW: Button for new component-based implementation
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/documents-v2');
                },
                icon: const Icon(Icons.science),
                label: const Text('Apri ToDo Lists V2 (Nuovi Componenti)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Original button
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/documents');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Apri ToDo Lists (Originale)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  side: BorderSide(color: Colors.purple[700]!, width: 2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Altre funzionalità in arrivo:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lista della spesa • Inventario dispensa • Note condivise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.check, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }
}
