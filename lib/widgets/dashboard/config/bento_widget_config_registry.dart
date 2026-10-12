import 'package:flutter/material.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/dashboard/config/bento_config_models.dart';

/// Registro asincrono che carica e costruisce le opzioni di configurazione per ogni widget
class BentoWidgetConfigRegistry {
  static Future<BentoWidgetConfigData> getConfigForWidget({
    required String type,
    Map<String, dynamic>? currentProps,
  }) async {
    final currentContext = ContextManager().currentContext;

    switch (type) {
      case 'balance':
        return _buildBalanceConfig(currentContext);

      case 'focus_tasks':
        return _buildFocusTasksConfig(currentContext);

      case 'shopping_quick_list':
        return _buildShoppingListConfig(currentContext);

      case 'habit_tracker':
        return _buildHabitTrackerConfig();

      case 'monthly_burn_rate':
        return _buildMonthlyBurnRateConfig();

      case 'hero_countdown':
        return _buildCountdownConfig();

      case 'pantry_alert':
        return _buildPantryConfig(currentContext);

      case 'note_stack':
        return _buildNoteStackConfig();

      case 'recent_notes':
        return _buildRecentNotesConfig();

      case 'investment_summary':
        return _buildInvestmentSummaryConfig();

      case 'recent_markdown':
        return _buildRecentMarkdownConfig(currentContext);

      default:
        return const BentoWidgetConfigData(
          title: 'Configura Widget',
          description: 'Personalizza il titolo e le proprietà di questo tile.',
          options: [],
        );
    }
  }

  // --- 1. Bilancio & Saldo ---
  static Future<BentoWidgetConfigData> _buildBalanceConfig(ExpenseContext context) async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'all',
        title: 'Tutti i Portafogli (Panoramica)',
        subtitle: 'Mostra il saldo totale e permette lo swipe tra tutti i conti',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF10B981),
        badge: 'Default',
        props: {'source': 'all', 'title': 'Tutti i Portafogli'},
      ),
    ];

    if (context.isGroup) {
      options.add(const BentoConfigOption(
        id: 'group_balance',
        title: 'Saldo di Gruppo',
        subtitle: 'Visualizza crediti e debiti con i membri del gruppo',
        icon: Icons.group_rounded,
        color: Color(0xFF6366F1),
        badge: 'Gruppo',
        props: {'source': 'group_balance', 'title': 'Saldo di Gruppo'},
      ));
    }

    try {
      final wallets = await WalletService().fetchWallets();
      for (final w in wallets) {
        options.add(BentoConfigOption(
          id: 'wallet_${w.id}',
          title: w.name,
          subtitle: '${w.currentBalance.toStringAsFixed(2)} € • Conto Singolo',
          icon: w.type.icon,
          color: w.color,
          props: {'source': 'wallet', 'walletId': w.id, 'title': w.name},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Bilancio',
      description: 'Scegli se mostrare la liquidità totale, il saldo comune o un conto specifico.',
      options: options,
      defaultOptionId: 'all',
    );
  }

  // --- 2. Focus Tasks ---
  static Future<BentoWidgetConfigData> _buildFocusTasksConfig(ExpenseContext context) async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'focus_today',
        title: 'Focus Oggi & Urgenti',
        subtitle: 'Attività in scadenza oggi o contrassegnate con priorità alta',
        icon: Icons.bolt_rounded,
        color: Color(0xFFF59E0B),
        badge: 'Consigliato',
        props: {'source': 'focus_today', 'title': 'Focus Oggi'},
      ),
    ];

    try {
      final docs = await DocumentService().getDocumentsForContext(context, 'todo');
      for (final doc in docs) {
        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Elenco task da documento',
          icon: Icons.checklist_rounded,
          color: const Color(0xFF6366F1),
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Focus Task',
      description: 'Decidi se aggregare le attività del giorno o collegare una lista To-Do specifica.',
      options: options,
      defaultOptionId: 'focus_today',
    );
  }

  // --- 3. Lista Spesa ---
  static Future<BentoWidgetConfigData> _buildShoppingListConfig(ExpenseContext context) async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'default',
        title: 'Lista della Spesa Principale',
        subtitle: 'Lista spesa rapida condivisa della dashboard',
        icon: Icons.shopping_cart_rounded,
        color: Color(0xFF3B82F6),
        badge: 'Predefinita',
        props: {'source': 'default', 'title': 'Lista Spesa'},
      ),
    ];

    try {
      final docs = await DocumentService().getDocumentsForContext(context, 'shopping_list');
      for (final doc in docs) {
        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Lista spesa specifica',
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFF3B82F6),
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Lista Spesa',
      description: 'Scegli quale elenco di prodotti mostrare sul widget della spesa.',
      options: options,
      defaultOptionId: 'default',
    );
  }

  // --- 4. Abitudini ---
  static Future<BentoWidgetConfigData> _buildHabitTrackerConfig() async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'all',
        title: 'Tutte le Routine',
        subtitle: 'Panoramica di tutte le abitudini e streak attivi',
        icon: Icons.loop_rounded,
        color: Color(0xFF06B6D4),
        badge: 'Completo',
        props: {'source': 'all', 'title': 'Abitudini'},
      ),
    ];

    try {
      final routines = await TimeManagementService().routinesStream.first.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => [],
      );
      for (final r in routines) {
        options.add(BentoConfigOption(
          id: 'routine_${r.id}',
          title: r.name,
          subtitle: 'Solo abitudini di questa routine',
          icon: Icons.repeat_rounded,
          color: const Color(0xFF06B6D4),
          props: {'source': 'routine', 'routineId': r.id, 'title': r.name},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Abitudini',
      description: 'Visualizza tutte le tue routine giornaliere o dedicati a una sequenza specifica.',
      options: options,
      defaultOptionId: 'all',
    );
  }

  // --- 5. Burn Rate & Budget ---
  static Future<BentoWidgetConfigData> _buildMonthlyBurnRateConfig() async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'all',
        title: 'Tutte le Spese (Burn Rate Globale)',
        subtitle: 'Monitora il ritmo di spesa complessivo del mese rispetto al budget',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFF97316),
        badge: 'Tutto',
        props: {'source': 'all', 'title': 'Burn Rate'},
      ),
    ];

    for (final t in Tipologia.values) {
      options.add(BentoConfigOption(
        id: 'cat_${t.name}',
        title: 'Solo ${t.name.toUpperCase()}',
        subtitle: 'Monitora esclusivamente le uscite per ${t.name}',
        icon: CategoryHelpers.getCategoryIcon(t),
        color: CategoryHelpers.getCategoryColor(t),
        props: {'source': 'category', 'category': t.name, 'title': t.name.toUpperCase()},
      ));
    }

    return BentoWidgetConfigData(
      title: 'Configura Burn Rate',
      description: 'Scegli se calcolare la velocità di spesa su tutte le uscite o isolare una categoria.',
      options: options,
      defaultOptionId: 'all',
    );
  }

  // --- 6. Countdown Evento ---
  static Future<BentoWidgetConfigData> _buildCountdownConfig() async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'auto',
        title: 'Prossimo Evento in Arrivo (Automatico)',
        subtitle: 'Aggancia automaticamente la data o viaggio più vicino nel tempo',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFEC4899),
        badge: 'Smart Auto',
        props: {'source': 'auto', 'title': 'Prossimo Evento'},
      ),
    ];

    try {
      final scenarios = await TimeManagementService().timeScenariosStream.first.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => [],
      );
      for (final s in scenarios) {
        IconData icon = Icons.event_rounded;
        Color color = const Color(0xFFEC4899);
        if (s.scenarioType.toLowerCase() == 'trip') {
          icon = Icons.flight_takeoff_rounded;
          color = const Color(0xFF38BDF8);
        } else if (s.scenarioType.toLowerCase() == 'outing') {
          icon = Icons.restaurant_rounded;
          color = const Color(0xFFFBBF24);
        }

        options.add(BentoConfigOption(
          id: 'scenario_${s.id}',
          title: s.title,
          subtitle: '${s.scenarioType.toUpperCase()} • ${s.startDate.day}/${s.startDate.month}/${s.startDate.year}',
          icon: icon,
          color: color,
          props: {'source': 'scenario', 'scenarioId': s.id, 'title': s.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Countdown',
      description: 'Scegli verso quale traguardo, viaggio o evento speciale orientare il conto alla rovescia.',
      options: options,
      defaultOptionId: 'auto',
    );
  }

  // --- 7. Dispensa ---
  static Future<BentoWidgetConfigData> _buildPantryConfig(ExpenseContext context) async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'default',
        title: 'Dispensa Principale',
        subtitle: 'Monitora tutte le scorte e i prodotti vicini alla scadenza',
        icon: Icons.kitchen_rounded,
        color: Color(0xFF10B981),
        badge: 'Default',
        props: {'source': 'default', 'title': 'Dispensa'},
      ),
    ];

    try {
      final docs = await DocumentService().getDocumentsForContext(context, 'dispensa');
      for (final doc in docs) {
        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Dispensa specifica',
          icon: Icons.kitchen_rounded,
          color: const Color(0xFF10B981),
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Dispensa',
      description: 'Seleziona quale dispensa o locale monitorare per prevenire gli sprechi alimentari.',
      options: options,
      defaultOptionId: 'default',
    );
  }

  // --- 8. Sticky Notes Stack ---
  static Future<BentoWidgetConfigData> _buildNoteStackConfig() async {
    return const BentoWidgetConfigData(
      title: 'Configura Sticky Notes',
      description: 'Scegli se mostrare tutte le note della pila o filtrare solo appunti con uno specifico colore.',
      options: [
        BentoConfigOption(
          id: 'all',
          title: 'Tutte le Note (Pila Completa)',
          subtitle: 'Sfoglia liberamente tutte le note create nella dashboard',
          icon: Icons.sticky_note_2_rounded,
          color: Color(0xFFEAB308),
          badge: 'Tutte',
          props: {'source': 'all', 'title': 'Sticky Notes'},
        ),
        BentoConfigOption(
          id: 'color_yellow',
          title: 'Solo Note Gialle (Idee Rapide)',
          subtitle: 'Filtra la pila mostrando solo i post-it classici gialli',
          icon: Icons.palette_rounded,
          color: Color(0xFFEAB308),
          props: {'source': 'color', 'colorFilter': 'yellow', 'title': 'Note Gialle'},
        ),
        BentoConfigOption(
          id: 'color_pink',
          title: 'Solo Note Rosa (Urgenti)',
          subtitle: 'Filtra la pila mostrando solo i post-it rosa',
          icon: Icons.palette_rounded,
          color: Color(0xFFEC4899),
          props: {'source': 'color', 'colorFilter': 'pink', 'title': 'Note Urgenti'},
        ),
        BentoConfigOption(
          id: 'color_blue',
          title: 'Solo Note Blu (Progetti & Studio)',
          subtitle: 'Filtra la pila mostrando solo i post-it blu',
          icon: Icons.palette_rounded,
          color: Color(0xFF3B82F6),
          props: {'source': 'color', 'colorFilter': 'blue', 'title': 'Note Studio'},
        ),
      ],
      defaultOptionId: 'all',
    );
  }

  // --- 9. Note Recenti ---
  static Future<BentoWidgetConfigData> _buildRecentNotesConfig() async {
    return const BentoWidgetConfigData(
      title: 'Configura Note Recenti',
      description: 'Scegli come ordinare e visualizzare l\'elenco compatto delle note.',
      options: [
        BentoConfigOption(
          id: 'all',
          title: 'Ultime Note Modificate',
          subtitle: 'Ordinamento cronologico con anteprima di testo inline',
          icon: Icons.notes_rounded,
          color: Color(0xFFF59E0B),
          badge: 'Cronologico',
          props: {'source': 'all', 'title': 'Note Recenti'},
        ),
        BentoConfigOption(
          id: 'pinned',
          title: 'Solo Note in Evidenza (Pinned)',
          subtitle: 'Mostra solo le note contrassegnate come importanti',
          icon: Icons.push_pin_rounded,
          color: Color(0xFFF59E0B),
          props: {'source': 'pinned', 'title': 'Note in Evidenza'},
        ),
      ],
      defaultOptionId: 'all',
    );
  }

  // --- 10. Investimenti & Net Worth ---
  static Future<BentoWidgetConfigData> _buildInvestmentSummaryConfig() async {
    return const BentoWidgetConfigData(
      title: 'Configura Investimenti',
      description: 'Personalizza la visualizzazione degli asset finanziari e patrimonio.',
      options: [
        BentoConfigOption(
          id: 'all',
          title: 'Patrimonio Complessivo (Net Worth)',
          subtitle: 'Aggrega liquidità, investimenti finanziari, metalli e beni fisici',
          icon: Icons.trending_up_rounded,
          color: Color(0xFF8B5CF6),
          badge: 'Net Worth',
          props: {'source': 'all', 'title': 'Patrimonio'},
        ),
        BentoConfigOption(
          id: 'liquid',
          title: 'Solo Mercati Finanziari (Azioni, ETF, Crypto)',
          subtitle: 'Isola gli strumenti ad alta volatilità e performance',
          icon: Icons.candlestick_chart_rounded,
          color: Color(0xFF8B5CF6),
          props: {'source': 'financial_only', 'title': 'Mercati & Crypto'},
        ),
      ],
      defaultOptionId: 'all',
    );
  }

  // --- 11. File Markdown ---
  static Future<BentoWidgetConfigData> _buildRecentMarkdownConfig(ExpenseContext context) async {
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'all',
        title: 'Tutti i Documenti Markdown',
        subtitle: 'Mostra gli ultimi file markdown aperti nel contesto attuale',
        icon: Icons.description_rounded,
        color: Color(0xFF6366F1),
        badge: 'Tutti',
        props: {'source': 'all', 'title': 'Documenti MD'},
      ),
    ];

    try {
      final docs = await DocumentService().getDocumentsForContext(context, 'markdown');
      for (final doc in docs) {
        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Documento markdown specifico',
          icon: Icons.article_rounded,
          color: const Color(0xFF6366F1),
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Documenti Markdown',
      description: 'Scegli se consultare i file recenti o fissare un documento di riferimento.',
      options: options,
      defaultOptionId: 'all',
    );
  }
}
