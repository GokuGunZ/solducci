import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/models/csv_column_preset.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/views/csv_staging_inbox_view.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class CsvColumnMapperView extends StatefulWidget {
  final String rawContent;
  final List<String> headers;
  final List<List<dynamic>> previewRows;
  final String delimiter;

  const CsvColumnMapperView({
    super.key,
    required this.rawContent,
    required this.headers,
    required this.previewRows,
    required this.delimiter,
  });

  @override
  State<CsvColumnMapperView> createState() => _CsvColumnMapperViewState();
}

class _CsvColumnMapperViewState extends State<CsvColumnMapperView> {
  String? _selectedDateCol;
  String? _selectedDescCol;
  String? _selectedAmountCol;
  String _dateFormat = 'dd/MM/yyyy';
  String _decimalSeparator = ',';
  final _presetNameController = TextEditingController(text: 'Mio Conto');

  @override
  void initState() {
    super.initState();
    _autoGuess();
  }

  void _autoGuess() {
    for (final h in widget.headers) {
      final lower = h.toLowerCase();
      if (_selectedDateCol == null && (lower.contains('data') || lower.contains('date'))) {
        _selectedDateCol = h;
      }
      if (_selectedDescCol == null && (lower.contains('causale') || lower.contains('descriz') || lower.contains('movimento'))) {
        _selectedDescCol = h;
      }
      if (_selectedAmountCol == null && (lower.contains('importo') || lower.contains('amount') || lower.contains('totale'))) {
        _selectedAmountCol = h;
      }
    }
  }

  void _proceedToInbox() {
    if (_selectedDateCol == null || _selectedDescCol == null || _selectedAmountCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona le 3 colonne obbligatorie: Data, Descrizione e Importo.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final customPreset = CsvColumnPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _presetNameController.text.trim().isNotEmpty
          ? _presetNameController.text.trim()
          : 'Conto Personalizzato',
      dateColumnName: _selectedDateCol!,
      descriptionColumnName: _selectedDescCol!,
      amountColumnName: _selectedAmountCol,
      dateFormat: _dateFormat,
      decimalSeparator: _decimalSeparator,
      delimiter: widget.delimiter,
    );

    final result = CsvParserService().parseCsvContent(
      widget.rawContent,
      preset: customPreset,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => CsvStagingInboxView(parseResult: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SolducciAppBar(
        title: const Text('Mappa Colonne CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.success, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Collega le colonne del tuo file con i campi di Solducci per completare l\'importazione.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Selettore Colonna Data
          _buildDropdownSection(
            label: '1. Colonna Data *',
            value: _selectedDateCol,
            items: widget.headers,
            onChanged: (val) => setState(() => _selectedDateCol = val),
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 16),

          // Selettore Colonna Descrizione
          _buildDropdownSection(
            label: '2. Colonna Descrizione / Causale *',
            value: _selectedDescCol,
            items: widget.headers,
            onChanged: (val) => setState(() => _selectedDescCol = val),
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),

          // Selettore Colonna Importo
          _buildDropdownSection(
            label: '3. Colonna Importo *',
            value: _selectedAmountCol,
            items: widget.headers,
            onChanged: (val) => setState(() => _selectedAmountCol = val),
            icon: Icons.euro_rounded,
          ),
          const SizedBox(height: 24),

          // Formato data & decimali
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Formati Numerici & Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Formato data', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _dateFormat,
                            dropdownColor: const Color(0xFF27272A),
                            decoration: _inputDecoration(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('GG/MM/AAAA')),
                              DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('AAAA-MM-GG')),
                              DropdownMenuItem(value: 'dd-MM-yyyy', child: Text('GG-MM-AAAA')),
                            ],
                            onChanged: (val) => setState(() => _dateFormat = val ?? 'dd/MM/yyyy'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Separatore decimali', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _decimalSeparator,
                            dropdownColor: const Color(0xFF27272A),
                            decoration: _inputDecoration(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: ',', child: Text('Virgola (,) IT')),
                              DropdownMenuItem(value: '.', child: Text('Punto (.) EN')),
                            ],
                            onChanged: (val) => setState(() => _decimalSeparator = val ?? ','),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Pulsante Procedi
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _proceedToInbox,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Procedi alla Staging Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          dropdownColor: const Color(0xFF27272A),
          decoration: _inputDecoration(prefixIcon: Icon(icon, color: AppTheme.success, size: 20)),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: const Text('Seleziona colonna...', style: TextStyle(color: Colors.white30, fontSize: 13)),
          items: items.map((col) => DropdownMenuItem(value: col, child: Text(col, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E1E22),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.success)),
    );
  }
}
