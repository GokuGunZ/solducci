import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/views/csv_column_mapper_view.dart';
import 'package:solducci/features/csv_importer/views/csv_staging_inbox_view.dart';
import 'package:solducci/theme/app_theme.dart';

class CsvImportFlow {
  /// Avvia il flusso di importazione CSV aprendo il selettore file nativo
  static Future<void> startImport(BuildContext context) async {
    try {
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il caricamento del file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
