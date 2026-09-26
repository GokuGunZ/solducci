#!/bin/bash

# Assicurati di essere nella cartella del progetto Flutter
PROJECT_ROOT=$(pwd)
LIB_DIR="$PROJECT_ROOT/lib"

echo "🛠️  Creazione struttura di base per l'app di ricevute..."

# 1. Cartelle principali
mkdir -p $LIB_DIR/{core/services,core/utils,models,view/home,view/widgets,data,config}

# 2. main.dart
cat > $LIB_DIR/main.dart <<EOF
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}
EOF

# 3. app.dart
cat > $LIB_DIR/app.dart <<EOF
import 'package:flutter/material.dart';
import 'view/home/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
EOF

# 4. receipt_model.dart
cat > $LIB_DIR/models/receipt_model.dart <<EOF
class Receipt {
  final String store;
  final DateTime date;
  final double total;

  Receipt({required this.store, required this.date, required this.total});

  Map<String, dynamic> toJson() => {
    'Negozio': store,
    'Data': date.toIso8601String(),
    'Totale': total.toStringAsFixed(2),
  };
}
EOF

# 5. ocr_service.dart
cat > $LIB_DIR/core/services/ocr_service.dart <<EOF
class OcrService {
  Future<String> extractTextFromImage(String imagePath) async {
    // TODO: integra tesseract_ocr
    return 'Simulated OCR result';
  }
}
EOF

# 6. image_picker_service.dart
cat > $LIB_DIR/core/services/image_picker_service.dart <<EOF
class ImagePickerService {
  Future<String?> pickImageFromCamera() async {
    // TODO: integra image_picker
    return null;
  }
}
EOF

# 7. google_sheets_service.dart
cat > $LIB_DIR/core/services/google_sheets_service.dart <<EOF
import '../../models/receipt_model.dart';

class GoogleSheetsService {
  Future<void> init() async {
    // TODO: autenticazione OAuth e setup
  }

  Future<void> sendReceipt(Receipt receipt) async {
    // TODO: invio dati al foglio
  }
}
EOF

# 8. receipt_parser.dart
cat > $LIB_DIR/core/utils/receipt_parser.dart <<EOF
import '../../models/receipt_model.dart';

class ReceiptParser {
  Receipt parse(String rawText) {
    // TODO: parsing regex
    return Receipt(
      store: 'Supermercato XYZ',
      date: DateTime.now(),
      total: 24.90,
    );
  }
}
EOF

# 9. home_screen.dart
cat > $LIB_DIR/view/home/home_screen.dart <<EOF
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scannerizza Scontrino')),
      body: const Center(child: Text('Home')),
    );
  }
}
EOF

# 10. home_view_model.dart
cat > $LIB_DIR/view/home/home_view_model.dart <<EOF
import '../../core/services/image_picker_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/google_sheets_service.dart';
import '../../core/utils/receipt_parser.dart';
import '../../models/receipt_model.dart';

class HomeViewModel {
  final ImagePickerService picker;
  final OcrService ocr;
  final ReceiptParser parser;
  final GoogleSheetsService sheets;

  Receipt? receipt;

  HomeViewModel({
    required this.picker,
    required this.ocr,
    required this.parser,
    required this.sheets,
  });

  Future<void> scanReceipt() async {
    final path = await picker.pickImageFromCamera();
    if (path == null) return;

    final rawText = await ocr.extractTextFromImage(path);
    final parsed = parser.parse(rawText);
    await sheets.sendReceipt(parsed);

    receipt = parsed;
  }
}
EOF

# 11. google_sheets_config.dart
cat > $LIB_DIR/config/google_sheets_config.dart <<EOF
class GoogleSheetsConfig {
  static const String spreadsheetId = 'INSERISCI_IL_TUO_ID';
  static const String range = 'Scontrini!A1:C1';
}
EOF

echo "✅ Struttura creata con successo."