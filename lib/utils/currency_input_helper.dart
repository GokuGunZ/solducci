class CurrencyInputHelper {
  /// Parses a string representing a monetary amount into a [double].
  /// Supports both comma (`,`) and dot (`.`) as decimal separators.
  /// Handles common formats:
  /// - `31.4` -> `31.4`
  /// - `31,4` -> `31.4`
  /// - `1.250,50` -> `1250.50`
  /// - `1,250.50` -> `1250.50`
  /// - `100` -> `100.0`
  static double? parse(String? input) {
    if (input == null) return null;
    String clean = input.replaceAll('€', '').replaceAll(r'$', '').trim();
    if (clean.isEmpty) return null;

    final hasDot = clean.contains('.');
    final hasComma = clean.contains(',');

    if (hasDot && hasComma) {
      final lastDot = clean.lastIndexOf('.');
      final lastComma = clean.lastIndexOf(',');
      if (lastDot > lastComma) {
        // e.g., 1,250.50 (US style) -> strip commas, keep dot
        clean = clean.replaceAll(',', '');
      } else {
        // e.g., 1.250,50 (EU style) -> strip dots, replace comma with dot
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (hasComma) {
      // Only comma: e.g., 31,4 or 1000,50 -> replace comma with dot
      clean = clean.replaceAll(',', '.');
    }
    // If only dot or no separators, keep as is (e.g., 31.4 or 100)

    // Remove any remaining spaces
    clean = clean.replaceAll(' ', '');

    return double.tryParse(clean);
  }
}
