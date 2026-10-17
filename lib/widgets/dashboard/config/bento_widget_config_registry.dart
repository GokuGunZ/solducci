import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/dashboard/config/bento_config_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      case 'unresolved_asterisks':
        return _buildAsterisksConfig(currentContext);

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
    final supabase = Supabase.instance.client;
    final options = <BentoConfigOption>[];

    // Preview for focus_today
    String? focusPreview;
    try {
      final now = DateTime.now();
      final endDayStr = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      final urgentTasks = await supabase
          .from('tasks')
          .select('title')
          .neq('status', 'completed')
          .or('priority.in.(urgent,high),due_date.lte.$endDayStr')
          .limit(3);
      final count = (urgentTasks as List).length;
      if (count > 0) {
        final titles = urgentTasks.map((t) => t['title'] as String).join(', ');
        focusPreview = '$count task: $titles';
      } else {
        focusPreview = 'Tutte le attività in pari 🎉';
      }
    } catch (_) {}

    options.add(BentoConfigOption(
      id: 'focus_today',
      title: 'Focus Oggi & Urgenti',
      subtitle: 'Attività in scadenza oggi o contrassegnate con priorità alta',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      badge: 'Consigliato',
      preview: focusPreview,
      props: {'source': 'focus_today', 'title': 'Focus Oggi'},
    ));

    try {
      final contextDocs = await DocumentService().getDocumentsForContext(context, 'todo');
      List<Document> userDocs = [];
      try {
        userDocs = await DocumentService().getDocumentsByType('todo').first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => [],
        );
      } catch (_) {}

      final Map<String, Document> uniqueDocs = {};
      for (final doc in contextDocs) {
        uniqueDocs[doc.id] = doc;
      }
      for (final doc in userDocs) {
        uniqueDocs[doc.id] = doc;
      }

      for (final doc in uniqueDocs.values) {
        String? docPreview;
        try {
          final res = await supabase
              .from('tasks')
              .select('title')
              .eq('document_id', doc.id)
              .neq('status', 'completed')
              .limit(3);
          final items = res as List;
          if (items.isNotEmpty) {
            final titles = items.map((t) => t['title'] as String).join(', ');
            docPreview = '${items.length}+ task: $titles';
          } else {
            docPreview = 'Nessun task attivo';
          }
        } catch (_) {}

        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Elenco task',
          icon: Icons.checklist_rounded,
          color: const Color(0xFF6366F1),
          preview: docPreview,
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Focus Task',
      description: 'Scegli quali liste task visualizzare nel widget (swipe per cambiare lista).',
      options: options,
      defaultOptionId: 'focus_today',
      isMultiSelect: true,
    );
  }

  // --- 3. Lista Spesa ---
  static Future<BentoWidgetConfigData> _buildShoppingListConfig(ExpenseContext context) async {
    final supabase = Supabase.instance.client;
    final options = <BentoConfigOption>[];

    try {
      final contextDocs = await DocumentService().getDocumentsForContext(context, 'shopping_list');
      List<Document> userDocs = [];
      try {
        userDocs = await DocumentService().getDocumentsByType('shopping_list').first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => [],
        );
      } catch (_) {}

      final Map<String, Document> uniqueDocs = {};
      for (final doc in contextDocs) {
        uniqueDocs[doc.id] = doc;
      }
      for (final doc in userDocs) {
        uniqueDocs[doc.id] = doc;
      }

      for (final doc in uniqueDocs.values) {
        String? docPreview;
        try {
          final res = await supabase
              .from('shopping_list_items')
              .select('name')
              .eq('document_id', doc.id)
              .eq('is_bought', false)
              .limit(3);
          final items = res as List;
          if (items.isNotEmpty) {
            final names = items.map((t) => t['name'] as String).join(', ');
            docPreview = '${items.length}+ prodotti: $names';
          } else {
            docPreview = 'Nessun prodotto da acquistare';
          }
        } catch (_) {}

        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Lista della spesa',
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFF10B981),
          preview: docPreview,
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Liste Spesa',
      description: 'Scegli quali liste della spesa includere nella navigazione del widget.',
      options: options,
      defaultOptionId: options.isNotEmpty ? options.first.id : null,
      isMultiSelect: true,
    );
  }

  // --- Asterischi ---
  static Future<BentoWidgetConfigData> _buildAsterisksConfig(ExpenseContext context) async {
    final supabase = Supabase.instance.client;
    final options = <BentoConfigOption>[];

    try {
      final docs = await DocumentService().getDocumentsForContext(context, 'asterisk');
      for (final doc in docs) {
        String? preview;
        try {
          final res = await supabase
              .from('asterisk_items')
              .select('content')
              .eq('document_id', doc.id)
              .eq('is_resolved', false)
              .limit(3);
          final items = res as List;
          if (items.isNotEmpty) {
            final contents = items.map((t) => t['content'] as String).join(', ');
            preview = '${items.length}+ aperti: $contents';
          } else {
            preview = 'Tutti risolti 🎉';
          }
        } catch (_) {}

        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Raccolta asterischi e note',
          icon: Icons.emergency,
          color: const Color(0xFFFBBF24),
          preview: preview,
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Asterischi',
      description: 'Scegli quali elenchi di asterischi visualizzare e navigare nel widget.',
      options: options,
      defaultOptionId: options.isNotEmpty ? options.first.id : null,
      isMultiSelect: true,
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
      isMultiSelect: true,
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
      description: 'Scegli se calcolare la velocità di spesa su tutte le uscite o quali categorie monitorare (swipe per cambiare categoria).',
      options: options,
      defaultOptionId: 'all',
      isMultiSelect: true,
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
      final now = DateTime.now();
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

        final diff = s.startDate.difference(now);
        String preview;
        if (diff.isNegative) {
          preview = s.endDate != null && s.endDate!.isAfter(now) ? 'In corso adesso' : 'Concluso';
        } else if (diff.inDays == 0) {
          preview = 'Oggi! Mancano poche ore';
        } else {
          preview = 'Mancano ${diff.inDays} ${diff.inDays == 1 ? "giorno" : "giorni"}';
        }

        options.add(BentoConfigOption(
          id: 'scenario_${s.id}',
          title: s.title,
          subtitle: '${s.scenarioType.toUpperCase()} • ${s.startDate.day}/${s.startDate.month}/${s.startDate.year}',
          icon: icon,
          color: color,
          preview: preview,
          props: {'source': 'scenario', 'scenarioId': s.id, 'title': s.title},
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Countdown',
      description: 'Scegli quali traguardi, viaggi o eventi visualizzare nel widget (swipe per cambiare evento).',
      options: options,
      defaultOptionId: 'auto',
      isMultiSelect: true,
    );
  }

  // --- 7. Dispensa ---
  static Future<BentoWidgetConfigData> _buildPantryConfig(ExpenseContext context) async {
    final supabase = Supabase.instance.client;
    final options = <BentoConfigOption>[];

    try {
      final contextDocs = await DocumentService().getDocumentsForContext(context, 'dispensa');
      List<Document> userDocs = [];
      try {
        userDocs = await DocumentService().getDocumentsByType('dispensa').first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => [],
        );
      } catch (_) {}

      final Map<String, Document> uniqueDocs = {};
      for (final doc in contextDocs) {
        uniqueDocs[doc.id] = doc;
      }
      for (final doc in userDocs) {
        uniqueDocs[doc.id] = doc;
      }

      for (final doc in uniqueDocs.values) {
        String? preview;
        try {
          final res = await supabase
              .from('pantry_items')
              .select('name')
              .eq('document_id', doc.id)
              .limit(3);
          final items = res as List;
          if (items.isNotEmpty) {
            final names = items.map((t) => t['name'] as String).join(', ');
            preview = '${items.length}+ prodotti: $names';
          } else {
            preview = 'Nessun prodotto censito';
          }
        } catch (_) {}

        options.add(BentoConfigOption(
          id: 'doc_${doc.id}',
          title: doc.title,
          subtitle: 'Dispensa',
          icon: Icons.kitchen_rounded,
          color: const Color(0xFF10B981),
          preview: preview,
          props: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
        ));
      }
    } catch (_) {}

    if (options.isEmpty) {
      options.add(const BentoConfigOption(
        id: 'default',
        title: 'Dispensa Principale',
        subtitle: 'Monitora tutte le scorte e i prodotti vicini alla scadenza',
        icon: Icons.kitchen_rounded,
        color: Color(0xFF10B981),
        badge: 'Default',
        props: {'source': 'default', 'title': 'Dispensa'},
      ));
    }

    return BentoWidgetConfigData(
      title: 'Configura Dispensa',
      description: 'Seleziona quali dispense o locali monitorare nel widget (swipe per cambiare dispensa).',
      options: options,
      defaultOptionId: options.isNotEmpty ? options.first.id : 'default',
      isMultiSelect: true,
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
    final options = <BentoConfigOption>[
      const BentoConfigOption(
        id: 'all',
        title: 'Patrimonio Complessivo (Tutti i Conti)',
        subtitle: 'Aggrega tutti i portafogli e asset finanziari',
        icon: Icons.trending_up_rounded,
        color: Color(0xFF8B5CF6),
        badge: 'Totale',
        props: {'source': 'all', 'title': 'Patrimonio'},
      ),
    ];

    try {
      final portfolios = await InvestmentPortfolioService().fetchPortfolios();
      await InvestmentAssetService().fetchAllAssets();
      final assetService = InvestmentAssetService();

      for (final p in portfolios) {
        final assets = assetService.getAssetsForPortfolio(p.id);
        final totalVal = assets.fold<double>(0.0, (sum, a) => sum + a.currentValue);
        final invested = assets.fold<double>(0.0, (sum, a) => sum + a.investedCapital);
        final pnl = totalVal - invested;
        final pnlPrefix = pnl >= 0 ? '+' : '';
        final preview = assets.isNotEmpty
            ? '${assets.length} asset • €${totalVal.toStringAsFixed(0)} ($pnlPrefix€${pnl.toStringAsFixed(0)})'
            : 'Nessun asset presente';

        options.add(BentoConfigOption(
          id: 'portfolio_${p.id}',
          title: p.name,
          subtitle: p.brokerName != null && p.brokerName!.isNotEmpty
              ? '${p.brokerName} • Conto Singolo'
              : 'Portafoglio Singolo',
          icon: Icons.account_balance_rounded,
          color: p.color,
          badge: p.brokerName,
          preview: preview,
          props: {
            'source': 'portfolio',
            'portfolioId': p.id,
            'title': p.name,
          },
        ));
      }
    } catch (_) {}

    return BentoWidgetConfigData(
      title: 'Configura Portafoglio Investimenti',
      description: 'Scegli se monitorare il patrimonio complessivo o quali conti/broker sfogliare nel widget (swipe per cambiare portafoglio).',
      options: options,
      defaultOptionId: 'all',
      isMultiSelect: true,
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
