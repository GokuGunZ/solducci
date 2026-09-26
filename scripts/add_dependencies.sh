#!/bin/bash

PUBSPEC="pubspec.yaml"

echo "📦 Aggiunta dipendenze a $PUBSPEC..."

# Dipendenze da aggiungere
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

# Salva la parte aggiornata in un file temporaneo
TEMP_FILE=$(mktemp)
echo "$DEPENDENCIES" > "$TEMP_FILE"

# Sovrascrive le dipendenze nel pubspec.yaml
awk -v newdeps="$TEMP_FILE" '
  BEGIN { inside=0 }
  /^dependencies:/ { inside=1; while ((getline line < newdeps) > 0) print line; next }
  /^dev_dependencies:/ { inside=0 }
  !inside { print }
' "$PUBSPEC" > pubspec.new.yaml

# Sostituisci il vecchio pubspec
mv pubspec.new.yaml "$PUBSPEC"
rm "$TEMP_FILE"

# Esegui flutter pub get
flutter pub get

echo "✅ Dipendenze aggiunte con successo."