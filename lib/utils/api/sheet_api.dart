import 'package:gsheets/gsheets.dart';
import 'package:solducci/models/expense.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'dart:convert';

class SheetApi {
  static const _sheetId = '1tzzoRxy7pfQ7NQvHoXU8XWp3aGniYdOLobth2GvzWMY';
  
  static GSheets? _sheets;
  static Worksheet? _allExpenses;

  static Future<void> initGSheets() async {
      final gsheetCreds = dotenv.maybeGet('GSHEET_CREDENTIALS') ??
      const String.fromEnvironment('GSHEET_CREDENTIALS');

  if (gsheetCreds.isEmpty) {
    throw Exception("❌ Nessuna credenziale GSHEET trovata!");
  }
    String? gcpCredJson = utf8.decode(base64Decode(gsheetCreds));
    _sheets = GSheets(gcpCredJson);
  }

  static Future init() async{
    initGSheets();
    final spreadsheet = await _sheets!.spreadsheet(_sheetId);
    _allExpenses = await _getWorkSheet(spreadsheet, title:'all_expenses_app');

    final firstRow =  Expense().getFieldsNames();
    _allExpenses!.values.insertRow(1, firstRow);
  }

  static Future<Worksheet> _getWorkSheet(Spreadsheet spreadsheet, {required String title,}) async {
    try{
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return spreadsheet.worksheetByTitle(title)!;
    }
    }

  static Future insert(Map<String, dynamic> expenseMap) async {
    if (_allExpenses == null) return;

    _allExpenses!.values.map.appendRow(expenseMap);
  }

}