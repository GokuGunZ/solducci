class LexoRank {
  static const String charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

  /// Generates a LexoRank string that sorts alphabetically between `prev` and `next`.
  /// If `prev` is null, it generates a string before `next`.
  /// If `next` is null, it generates a string after `prev`.
  /// If both are null, it generates a middle string.
  static String between(String? prev, String? next) {
    if (prev == null && next == null) return _char(charset.length ~/ 2);
    
    String pStr = prev ?? _char(0);
    String nStr = next ?? _char(charset.length - 1);
    
    if (pStr == nStr) return pStr; // Should not happen in normal conditions

    String result = "";
    int pos = 0;
    
    while (true) {
      int p = pos < pStr.length ? charset.indexOf(pStr[pos]) : 0;
      int n = pos < nStr.length ? charset.indexOf(nStr[pos]) : charset.length;
      
      if (p == n) {
        result += charset[p];
        pos++;
        continue;
      }
      
      if (n - p > 1) {
        int mid = p + ((n - p) / 2).floor();
        result += charset[mid];
        return result;
      } else {
        // n - p == 1 (consecutive characters)
        result += charset[p];
        pos++;
        // Pad the `nStr` boundary string with the maximum character so we can find a midpoint on the next iteration
        nStr = nStr.length > pos ? nStr : result + charset[charset.length - 1];
      }
    }
  }

  static String _char(int index) => charset[index];
}
