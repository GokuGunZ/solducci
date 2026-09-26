#!/bin/bash

PROJECT_ROOT=$(pwd)
LIB_DIR="$PROJECT_ROOT/lib"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

echo "🚀 Inizializzazione progetto Flutter per gestione scontrini..."

### CREAZIONE STRUTTURA ###

mkdir -p $LIB_DIR/{core/services,core/utils,models,view/home,view/widgets,data,config}

cat > $LIB_DIR/main.dart <<EOF
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}
EOF

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

cat > $LIB_DIR/core/services/ocr_service.dart <<EOF
class OcrService {
  Future<String> extractTextFromImage(String imagePath) async {
    // TODO: integra tesseract_ocr
    return 'Simulated OCR result';
  }
}
EOF

cat > $LIB_DIR/core/services/image_picker_service.dart <<EOF
class ImagePickerService {
  Future<String?> pickImageFromCamera() async {
    // TODO: integra image_picker
    return null;
  }
}
EOF

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

cat > $LIB_DIR/config/google_sheets_config.dart <<EOF
class GoogleSheetsConfig {
  static const String spreadsheetId = 'INSERISCI_IL_TUO_ID';
  static const String range = 'Scontrini!A1:C1';
}
EOF

echo "📂 Struttura file creata."

### AGGIUNTA DIPENDENZE ###

echo "📦 Aggiunta dipendenze a $PUBSPEC..."

DEPENDENCIES=$(cat <<EOF
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.0
  tesseract_ocr: ^0.3.1
  googleapis: ^12.0.0
  googleapis_auth: ^1.6.0
  path_provider: ^2.1.2
  http: ^1.2.1
  intl: ^0.19.0
  provider: ^6.1.2
EOF
)

TEMP_FILE=$(mktemp)
echo "$DEPENDENCIES" > "$TEMP_FILE"

awk -v newdeps="$TEMP_FILE" '
  BEGIN { inside=0 }
  /^dependencies:/ { inside=1; while ((getline line < newdeps) > 0) print line; next }
  /^dev_dependencies:/ { inside=0 }
  !inside { print }
' "$PUBSPEC" > pubspec.new.yaml

mv pubspec.new.yaml "$PUBSPEC"
rm "$TEMP_FILE"

flutter pub get

echo "✅ Progetto inizializzato con successo!"