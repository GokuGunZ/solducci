import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/services/merchant_rule_service.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class MerchantRulesManagerView extends StatefulWidget {
  const MerchantRulesManagerView({super.key});

  @override
  State<MerchantRulesManagerView> createState() => _MerchantRulesManagerViewState();
}

class _MerchantRulesManagerViewState extends State<MerchantRulesManagerView> {
  final _ruleService = MerchantRuleService();
  List<MerchantRule> _rules = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    final rules = await _ruleService.getRules();
    if (mounted) {
      setState(() {
        _rules = List.from(rules);
        _isLoading = false;
      });
    }
  }

  List<MerchantRule> get _filteredRules {
    if (_searchQuery.trim().isEmpty) return _rules;
    final q = _searchQuery.toLowerCase().trim();
    return _rules.where((r) {
      return r.pattern.toLowerCase().contains(q) ||
          r.cleanName.toLowerCase().contains(q) ||
          r.defaultCategory.label.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openRuleDialog({MerchantRule? existingRule}) async {
    final patternController = TextEditingController(text: existingRule?.pattern ?? '');
    final nameController = TextEditingController(text: existingRule?.cleanName ?? '');
    var selectedCategory = existingRule?.defaultCategory ?? Tipologia.cibo;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final catColor = CategoryPickerSheet.getColor(selectedCategory);
          final catIcon = CategoryPickerSheet.getIcon(selectedCategory);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      existingRule != null ? 'Modifica Regola' : 'Nuova Regola Esercente',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quando un movimento bancario contiene questo pattern, Solducci lo assegnerà in automatico.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Campo Pattern
                    const Text('Parola chiave nel CSV (Pattern)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: patternController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Es. CONAD, ESSELUNGA, NETFLIX...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Nome Pulito
                    const Text('Nome pulito / Alias da salvare', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Es. Conad Spesa, Netflix...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selettore Categoria
                    const Text('Categoria predefinita', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (c) => CategoryPickerSheet(
                            currentCategory: selectedCategory,
                            onCategorySelected: (cat) {
                              setSheetState(() => selectedCategory = cat);
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: catColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(catIcon, color: catColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              selectedCategory.label,
                              style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pulsante Salva
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final pattern = patternController.text.trim();
                          final cleanName = nameController.text.trim();

                          if (pattern.isEmpty || cleanName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Compila sia il pattern che il nome pulito'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          final newRule = MerchantRule(
                            id: existingRule?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
                            pattern: pattern,
                            cleanName: cleanName,
                            defaultCategory: selectedCategory,
                          );

                          await _ruleService.saveRule(newRule);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadRules();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Salva Regola', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteRule(MerchantRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina Regola', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
          'Vuoi davvero eliminare la regola per "${rule.cleanName}"?\nNei prossimi CSV non verrà più applicata automaticamente.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _ruleService.deleteRule(rule.id);
      _loadRules();
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ripristina Predefiniti', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Questo sostituirà le regole attuali con quelle predefinite di Solducci (Esselunga, Conad, Coop, Eni, Netflix...). Vuoi procedere?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ripristina', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _ruleService.resetToDefaults();
      _loadRules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SolducciAppBar(
        title: const Text('Regole Esercenti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded, color: Colors.white70),
            tooltip: 'Ripristina predefiniti',
            onPressed: _resetDefaults,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openRuleDialog(),
        backgroundColor: AppTheme.success,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
          : Column(
              children: [
                // Barra di Ricerca
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cerca tra le regole...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF18181B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.success)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                // Lista Regole
                Expanded(
                  child: _filteredRules.isEmpty
                      ? const Center(
                          child: Text('Nessuna regola trovata', style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filteredRules.length,
                          itemBuilder: (ctx, idx) {
                            final rule = _filteredRules[idx];
                            final catColor = CategoryPickerSheet.getColor(rule.defaultCategory);
                            final catIcon = CategoryPickerSheet.getIcon(rule.defaultCategory);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: catColor.withOpacity(0.15),
                                  child: Icon(catIcon, color: catColor, size: 20),
                                ),
                                title: Text(
                                  rule.cleanName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Contiene: "${rule.pattern}"',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rule.defaultCategory.label,
                                      style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 20),
                                      onPressed: () => _openRuleDialog(existingRule: rule),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () => _deleteRule(rule),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
