import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:uuid/uuid.dart';

/// Rappresenta un modello/preset di layout completo per la Bento Dashboard
class BentoPreset {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String category; // 'finance', 'productivity', 'home', 'minimal', 'custom'
  final List<BentoWidgetDef> layout;
  final bool isCustom;

  const BentoPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.category,
    required this.layout,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isCustom': isCustom,
      'layout': layout.map((w) => w.toMap()).toList(),
    };
  }

  factory BentoPreset.fromMap(Map<String, dynamic> map) {
    final rawLayout = map['layout'] as List<dynamic>? ?? [];
    return BentoPreset(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      icon: Icons.dashboard_customize_rounded,
      accentColor: const Color(0xFF6366F1),
      category: map['category'] as String? ?? 'custom',
      isCustom: map['isCustom'] as bool? ?? true,
      layout: rawLayout.map((e) => BentoWidgetDef.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Catalogo dei preset curati per Solducci Bento Home
class BentoPresetCatalog {
  static final List<BentoPreset> curatedPresets = [
    // 1. Finanza & Controllo
    BentoPreset(
      id: 'preset_finance',
      title: 'Finanza & Controllo',
      description: 'Monitoraggio completo di entrate, uscite, burn rate e patrimonio con inserimento veloce.',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: const Color(0xFF10B981),
      category: 'finance',
      layout: [
        BentoWidgetDef(id: const Uuid().v4(), type: 'balance', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'daily_progress', size: const BentoWidgetSize(1, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'pantry_alert', size: const BentoWidgetSize(1, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'quick_expense', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'monthly_burn_rate', size: const BentoWidgetSize(2, 2)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'investment_summary', size: const BentoWidgetSize(2, 2)),
      ],
    ),

    // 2. Second Brain & Idee
    BentoPreset(
      id: 'preset_notes',
      title: 'Second Brain & Idee',
      description: 'Il tuo centro pensieri: pila di post-it colorati, elenco note veloci e attività cardine.',
      icon: Icons.sticky_note_2_rounded,
      accentColor: const Color(0xFFF59E0B),
      category: 'productivity',
      layout: [
        BentoWidgetDef(id: const Uuid().v4(), type: 'note_stack', size: const BentoWidgetSize(2, 3)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'recent_notes', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'focus_tasks', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'recent_markdown', size: const BentoWidgetSize(2, 3)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'unresolved_asterisks', size: const BentoWidgetSize(2, 2)),
      ],
    ),

    // 3. Casa & Condivisione (Ideale per Gruppi)
    BentoPreset(
      id: 'preset_home',
      title: 'Casa & Spazio Comune',
      description: 'Ideale per convivenza, spesa di gruppo, rifornimento dispensa e questioni aperte.',
      icon: Icons.home_work_rounded,
      accentColor: const Color(0xFF3B82F6),
      category: 'home',
      layout: [
        BentoWidgetDef(id: const Uuid().v4(), type: 'balance', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'pantry_alert', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'shopping_quick_list', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'quick_expense', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'unresolved_asterisks', size: const BentoWidgetSize(2, 2)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'note_stack', size: const BentoWidgetSize(2, 3)),
      ],
    ),

    // 4. Focus & Minimalista
    BentoPreset(
      id: 'preset_minimal',
      title: 'Focus & Essenziale',
      description: 'Pulito e privo di distrazioni: solo saldo rapido, spese del giorno, task e abitudini.',
      icon: Icons.center_focus_strong_rounded,
      accentColor: const Color(0xFF6366F1),
      category: 'minimal',
      layout: [
        BentoWidgetDef(id: const Uuid().v4(), type: 'balance', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'daily_progress', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'focus_tasks', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'habit_tracker', size: const BentoWidgetSize(2, 2)),
      ],
    ),

    // 5. Tuttofare (All-In-One)
    BentoPreset(
      id: 'preset_power',
      title: 'Dashboard Completa',
      description: 'La panoramica completa a mosaico che unisce finanze personali, task del giorno e post-it.',
      icon: Icons.grid_view_rounded,
      accentColor: const Color(0xFF8B5CF6),
      category: 'productivity',
      layout: [
        BentoWidgetDef(id: const Uuid().v4(), type: 'balance', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'daily_progress', size: const BentoWidgetSize(2, 1)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'quick_expense', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'focus_tasks', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'note_stack', size: const BentoWidgetSize(2, 3)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'shopping_quick_list', size: const BentoWidgetSize(2, 4)),
        BentoWidgetDef(id: const Uuid().v4(), type: 'habit_tracker', size: const BentoWidgetSize(2, 2)),
      ],
    ),
  ];

  static BentoPreset? findById(String id) {
    try {
      return curatedPresets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Restituisce il preset consigliato in base al contesto attivo
  static BentoPreset getRecommendedForContext({required bool isGroup}) {
    if (isGroup) {
      return curatedPresets.firstWhere((p) => p.id == 'preset_home');
    }
    return curatedPresets.firstWhere((p) => p.id == 'preset_finance');
  }
}
