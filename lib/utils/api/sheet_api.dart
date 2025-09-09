// lib/utils/api/sheet_api.dart
import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:solducci/models/expense.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class SheetApi {
  static const _sheetId = '1tzzoRxy7pfQ7NQvHoXU8XWp3aGniYdOLobth2GvzWMY';

  static GSheets? _sheets;
  static Worksheet? _allExpenses;

  static Future<void> initGSheets() async {
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: "assets/dev/.env");
      envLoaded = true;
      debugPrint("✅ .env caricato");
    } catch (_) {
      debugPrint("⚠️ Nessun file .env trovato, userò --dart-define");
    }

    final envCred = envLoaded ? dotenv.maybeGet('GSHEET_CREDENTIALS') : null;
    final defineCred = const String.fromEnvironment('GSHEET_CREDENTIALS');

    String? gsheetCreds;
    if (envCred != null && envCred.isNotEmpty) {
      gsheetCreds = envCred;
      debugPrint('✅ GSHEET_CREDENTIALS trovata in .env (lunghezza: ${envCred.length})');
    } else if (defineCred.isNotEmpty) {
      gsheetCreds = defineCred;
      debugPrint('✅ GSHEET_CREDENTIALS trovata via --dart-define (lunghezza: ${defineCred.length})');
    }

    if (gsheetCreds == null || gsheetCreds.isEmpty) {
      throw Exception(
          "❌ Nessuna credenziale GSHEET trovata! Metti un base64 della service-account in assets/dev/.env (GSHEET_CREDENTIALS=...) o passa --dart-define=GSHEET_CREDENTIALS=<BASE64> al build.");
    }

    try {
      final jsonString = utf8.decode(base64Decode(gsheetCreds));
      _sheets = GSheets(jsonString);
      debugPrint("✅ GSheets inizializzato correttamente");
    } catch (e) {
      throw Exception("❌ Errore durante la decodifica/inizializzazione GSHEET: $e");
    }
  }

  static Future<void> init() async {
    await initGSheets();

    final spreadsheet = await _sheets!.spreadsheet(_sheetId);
    _allExpenses = await _getWorkSheet(spreadsheet, title: 'all_expenses_app');

    final firstRow = Expense().getFieldsNames();

    // se la prima riga (header) è vuota, inseriscila; altrimenti non duplicare
    try {
      final header = await _allExpenses!.values.row(1);
      if (header == null || header.isEmpty) {
        await _allExpenses!.values.insertRow(1, firstRow);
        debugPrint("✅ Header inserito nella sheet");
      } else {
        debugPrint("⚠️ Header già presente: $header");
      }
    } catch (e) {
      debugPrint("⚠️ Impossibile leggere prima riga (provo a inserire): $e");
      await _allExpenses!.values.insertRow(1, firstRow);
    }
  }

  static Future<Worksheet> _getWorkSheet(Spreadsheet spreadsheet, {required String title}) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      final ws = spreadsheet.worksheetByTitle(title);
      if (ws == null) rethrow;
      return ws;
    }
  }

  static Future<void> insert(Map<String, dynamic> expenseMap) async {
    if (_allExpenses == null) {
      debugPrint("⚠️ insert chiamato ma _allExpenses è null");
      return;
    }
    await _allExpenses!.values.map.appendRow(expenseMap);
  }
}