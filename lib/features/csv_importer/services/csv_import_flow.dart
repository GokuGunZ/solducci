import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/services/csv_staging_service.dart';
import 'package:solducci/features/csv_importer/views/csv_column_mapper_view.dart';
import 'package:solducci/features/csv_importer/views/csv_staging_inbox_view.dart';
import 'package:solducci/theme/app_theme.dart';

class CsvImportFlow {
  /// Apre direttamente la Staging Inbox con i movimenti attualmente salvati in bozza
  static Future<void> openPendingDraft(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const CsvStagingInboxView(),
      ),
    );
  }

  /// Avvia il flusso di importazione CSV. Se è presente una bozza, chiede se riprenderla
  /// o caricare un nuovo file.
  static Future<void> startImport(BuildContext context) async {
    try {
      final stagingService = CsvStagingService();
      final hasDraft = await stagingService.hasPendingDraft();
      final pendingCount = await stagingService.getPendingCount();

      if (!context.mounted) return;

      if (hasDraft) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: const Color(0xFF1E1E22),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.inbox_rounded, color: AppTheme.success, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Staging Inbox in Sospeso',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hai $pendingCount movimenti non ancora importati',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Opzione 1: Riprendi bozza
                  ListTile(
                    tileColor: const Color(0xFF27272A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.success, size: 26),
                    title: const Text('Riprendi la Bozza Attiva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Continua a gestire i $pendingCount movimenti salvati', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => Navigator.pop(ctx, 'resume'),
                  ),
                  const SizedBox(height: 12),

                  // Opzione 2: Carica nuovo file
                  ListTile(
                    tileColor: const Color(0xFF27272A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.upload_file_rounded, color: Colors.white70, size: 24),
                    title: const Text('Carica un Nuovo File CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Seleziona un nuovo estratto conto dal tuo dispositivo', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => Navigator.pop(ctx, 'new_file'),
                  ),
                ],
              ),
            ),
          ),
        );

        if (choice == 'resume') {
          if (context.mounted) {
            await openPendingDraft(context);
          }
          return;
        } else if (choice == null) {
          return; // Utente ha chiuso il foglio
        }
      }

      if (!context.mounted) return;

      // Procedi al caricamento di un nuovo file
      await _pickAndParseFile(context, hasExistingDraft: hasDraft);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'importazione: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  static Future<void> _pickAndParseFile(BuildContext context, {required bool hasExistingDraft}) async {
    final pickerResult = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) {
      return; // Utente ha annullato
    }

    final file = pickerResult.files.first;
    List<int>? bytes = file.bytes;

    final filePath = file.path;
    if (bytes == null && filePath != null && !kIsWeb) {
      bytes = await File(filePath).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File CSV vuoto o illeggibile'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final parser = CsvParserService();
    final content = parser.decodeCsvBytes(bytes);
    final parseResult = parser.parseCsvContent(content);

    if (!context.mounted) return;

    if (parseResult.headers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile trovare intestazioni valide nel file CSV'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Se esiste già una bozza attiva, chiedi se unire o sostituire
    if (hasExistingDraft && parseResult.transactions.isNotEmpty) {
      final shouldMerge = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Bozza Esistente Rilevata', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Text(
            'Ci sono già movimenti in attesa nella Staging Inbox.\n\n'
            'Vuoi unire i ${parseResult.transactions.length} nuovi movimenti a quelli già presenti, '
            'oppure sostituire completamente la bozza?',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // Sostituisci
              child: const Text('Sostituisci', style: TextStyle(color: Color(0xFFEF4444))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), // Unisci
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Unisci Movimenti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldMerge == true) {
        await CsvStagingService().appendTransactions(
          parseResult.transactions,
          fileName: file.name,
        );
        if (context.mounted) {
          await openPendingDraft(context);
        }
        return;
      } else if (shouldMerge == false) {
        await CsvStagingService().clearStaging();
      } else {
        return; // Utente ha annullato
      }
    }

    if (!context.mounted) return;

    // Se il preset è stato riconosciuto automaticamente e ci sono transazioni
    if (parseResult.matchedPreset != null && parseResult.transactions.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => CsvStagingInboxView(parseResult: parseResult),
        ),
      );
    } else {
      // Altrimenti apri la schermata di mapping visuale con anteprima
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => CsvColumnMapperView(
            rawContent: content,
            headers: parseResult.headers,
            previewRows: parseResult.rawRows.take(3).toList(),
            delimiter: parseResult.delimiter,
          ),
        ),
      );
    }
  }
}
