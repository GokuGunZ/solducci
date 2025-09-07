import 'package:flutter/material.dart';
import 'package:solducci/views/homescreen/main.dart';
import 'package:solducci/utils/api/sheet_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/dev/.env");
    debugPrint("✅ .env caricato");
  } catch (_) {
    debugPrint("⚠️ Nessun file .env trovato, userò --dart-define");
  }
  await SheetApi.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    ));
}
