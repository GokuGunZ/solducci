import 'dart:math';

/// Stable anchor tracking an external entity's association with a Markdown line.
class LineAnchor {
  final String entityId;
  String lastText;
  int lastPosition;
  String contextSignature; // Hash of prev | curr | next

  LineAnchor({
    required this.entityId,
    required this.lastText,
    required this.lastPosition,
    required this.contextSignature,
  });

  Map<String, dynamic> toMap() => {
    'entity_id': entityId,
    'last_text': lastText,
    'last_position': lastPosition,
    'context_signature': contextSignature,
  };

  factory LineAnchor.fromMap(Map<String, dynamic> map) => LineAnchor(
    entityId: map['entity_id'] as String,
    lastText: map['last_text'] as String,
    lastPosition: map['last_position'] as int? ?? 0,
    contextSignature: map['context_signature'] as String? ?? '',
  );
}

/// Result of a reconciliation pass.
class ReconciliationResult {
  final Map<String, int> matched; // entityId -> lineIndex
  final List<String> quarantined; // entityIds with ambiguous resolution (protected from mutation)
  final List<int> newLines; // indices of newly added lines requiring entity creation
  final Map<String, double> confidence; // entityId -> confidence score [0.0 - 1.0]

  const ReconciliationResult({
    required this.matched,
    required this.quarantined,
    required this.newLines,
    required this.confidence,
  });
}

/// Independent, multi-factor hybrid reconciler correlating Markdown lines
/// to domain entities without inline IDs or document pollution.
class HybridLineReconciler {
  final double similarityThreshold;
  final List<LineAnchor> _anchors = [];

  HybridLineReconciler({this.similarityThreshold = 0.50});

  List<LineAnchor> get anchors => List.unmodifiable(_anchors);

  /// Registers initial anchors from existing lines and entity IDs.
  void setInitialAnchors(List<String> lines, Map<String, String> entityIdToText) {
    _anchors.clear();
    int pos = 0;
    for (var entry in entityIdToText.entries) {
      final text = entry.value;
      // find line position
      int lineIdx = lines.indexWhere((l) => _cleanText(l).contains(_cleanText(text)));
      if (lineIdx == -1) lineIdx = pos;

      final prev = lineIdx > 0 ? _cleanText(lines[lineIdx - 1]) : '';
      final curr = _cleanText(lines[min(lineIdx, lines.length - 1)]);
      final next = lineIdx < lines.length - 1 ? _cleanText(lines[lineIdx + 1]) : '';
      final ctxSig = '$prev|$curr|$next'.hashCode.toString();

      _anchors.add(LineAnchor(
        entityId: entry.key,
        lastText: text,
        lastPosition: lineIdx,
        contextSignature: ctxSig,
      ));
      pos++;
    }
  }

  /// Reconciles [newLines] against registered anchors.
  ///
  /// Guarantees:
  /// 1. In-place exact preservation when position and text are unchanged.
  /// 2. Zero false assignment when context signature is intact.
  /// 3. Ambiguity quarantine when duplicate lines collide without context.
  /// 4. Resilient tracking during in-place word insertions/corrections.
  ReconciliationResult reconcile(List<String> newLines) {
    final matched = <String, int>{};
    final quarantined = <String>[];
    final confidence = <String, double>{};
    final usedLines = <int>{};

    final cleanedNewLines = newLines.map(_cleanText).toList();

    // Stage 0: Direct In-Place Match (Same index & exact text)
    // If the line has not moved and text is identical, lock it immediately
    for (var anchor in _anchors) {
      final idx = anchor.lastPosition;
      if (idx >= 0 && idx < newLines.length && !usedLines.contains(idx)) {
        if (cleanedNewLines[idx] == _cleanText(anchor.lastText)) {
          matched[anchor.entityId] = idx;
          confidence[anchor.entityId] = 1.0;
          usedLines.add(idx);
        }
      }
    }

    // Stage 1: Exact N-gram Context Match (Confidence: 0.95)
    // Prioritize candidates closest to anchor.lastPosition
    for (var anchor in _anchors) {
      if (matched.containsKey(anchor.entityId)) continue;

      int bestIdx = -1;
      int minDistance = 999999;

      for (int i = 0; i < newLines.length; i++) {
        if (usedLines.contains(i)) continue;

        final prev = i > 0 ? cleanedNewLines[i - 1] : '';
        final curr = cleanedNewLines[i];
        final next = i < newLines.length - 1 ? cleanedNewLines[i + 1] : '';
        final ctxSig = '$prev|$curr|$next'.hashCode.toString();

        if (curr == _cleanText(anchor.lastText) && ctxSig == anchor.contextSignature) {
          final dist = (i - anchor.lastPosition).abs();
          if (dist < minDistance) {
            minDistance = dist;
            bestIdx = i;
          }
        }
      }

      if (bestIdx != -1) {
        matched[anchor.entityId] = bestIdx;
        confidence[anchor.entityId] = 0.95;
        usedLines.add(bestIdx);
      }
    }

    // Stage 2: Exact Content Match with Duplicate Quarantine (Confidence: 0.85)
    for (var anchor in _anchors) {
      if (matched.containsKey(anchor.entityId)) continue;

      final targetClean = _cleanText(anchor.lastText);
      final candidateIndices = <int>[];

      for (int i = 0; i < newLines.length; i++) {
        if (usedLines.contains(i)) continue;
        if (cleanedNewLines[i] == targetClean) {
          candidateIndices.add(i);
        }
      }

      if (candidateIndices.length == 1) {
        final chosen = candidateIndices.first;
        matched[anchor.entityId] = chosen;
        confidence[anchor.entityId] = 0.85;
        usedLines.add(chosen);
      } else if (candidateIndices.length > 1) {
        // AMBIGUITY DETECTED: multiple duplicate candidates without contextual differentiator
        // Quarantine to prevent accidental deletion or state corruption!
        quarantined.add(anchor.entityId);
      }
    }

    // Stage 3: Word-level Dice Token Similarity & Fuzzy Tracking (Confidence: 0.50 - 0.80)
    for (var anchor in _anchors) {
      if (matched.containsKey(anchor.entityId) || quarantined.contains(anchor.entityId)) continue;

      int bestLine = -1;
      double highestScore = 0.0;
      final targetClean = _cleanText(anchor.lastText);

      for (int i = 0; i < newLines.length; i++) {
        if (usedLines.contains(i)) continue;

        final score = calculateDiceSimilarity(targetClean, cleanedNewLines[i]);
        if (score >= similarityThreshold && score > highestScore) {
          highestScore = score;
          bestLine = i;
        }
      }

      if (bestLine != -1) {
        matched[anchor.entityId] = bestLine;
        confidence[anchor.entityId] = highestScore;
        usedLines.add(bestLine);
      } else {
        // Line unmapped: safe soft-delete / archive candidate
        matched[anchor.entityId] = -1;
        confidence[anchor.entityId] = 0.0;
      }
    }

    // Detect new checklist/bullet lines that have no anchor
    final newLinesList = <int>[];
    for (int i = 0; i < newLines.length; i++) {
      if (!usedLines.contains(i)) {
        final line = newLines[i].trim();
        if (line.startsWith('- [ ]') || line.startsWith('- [x]') || line.startsWith('* [ ]') || line.startsWith('* [x]')) {
          newLinesList.add(i);
        }
      }
    }

    return ReconciliationResult(
      matched: matched,
      quarantined: quarantined,
      newLines: newLinesList,
      confidence: confidence,
    );
  }

  /// Calculates word-level Dice similarity coefficient between [s1] and [s2].
  ///
  /// $$\text{Dice}(A, B) = \frac{2 |A \cap B|}{|A| + |B|}$$
  static double calculateDiceSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final words1 = s1.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final words2 = s2.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2);
    if (intersection.isEmpty) return 0.0;

    return (2.0 * intersection.length) / (words1.length + words2.length);
  }

  static String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'^\s*[-*+]\s+(\[[ xX-]\]\s+)?'), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+'), '')
        .replaceAll(RegExp(r'^\s*#{1,6}\s+'), '')
        .replaceAll(RegExp(r'^\s*>\s+'), '')
        .trim();
  }
}
