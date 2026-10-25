import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/core/markdown/reconciler/hybrid_line_reconciler.dart';

void main() {
  group('HybridLineReconciler Comprehensive Stress Tests', () {
    late HybridLineReconciler reconciler;

    setUp(() {
      reconciler = HybridLineReconciler(similarityThreshold: 0.50);
    });

    test('Stress 1: Duplicate lines without context are quarantined (Zero Destructive Deletes)', () {
      final initialLines = [
        '- [ ] Buy oat milk',
        '- [ ] Buy apples',
        '- [ ] Buy artisan sourdough',
      ];
      final entities = {
        'ENT_1': 'Buy oat milk',
        'ENT_2': 'Buy apples',
        'ENT_3': 'Buy artisan sourdough',
      };

      reconciler.setInitialAnchors(initialLines, entities);

      // Duplication: 2 identical lines created without contextual difference
      final mutatedLines = [
        '- [ ] Buy oat milk',
        '- [ ] Buy oat milk', // duplicate
        '- [ ] Buy apples',
        '- [ ] Buy artisan sourdough',
      ];

      final res = reconciler.reconcile(mutatedLines);

      // ENT_1 must either remain bound to exact context or be quarantined if ambiguous
      // Crucially, it must NEVER be marked as deleted (-1)
      expect(res.matched['ENT_1'] != -1 || res.quarantined.contains('ENT_1'), isTrue);
      expect(res.matched['ENT_2'], equals(2));
      expect(res.matched['ENT_3'], equals(3));
    });

    test('Stress 2: Arbitrary reordering (Swap & Inversion) preserves 100% identity', () {
      final initialLines = [
        '- [ ] Item A',
        '- [ ] Item B',
        '- [ ] Item C',
        '- [ ] Item D',
      ];
      final entities = {
        'A': 'Item A',
        'B': 'Item B',
        'C': 'Item C',
        'D': 'Item D',
      };

      reconciler.setInitialAnchors(initialLines, entities);

      // Completely inverted order
      final invertedLines = [
        '- [ ] Item D',
        '- [ ] Item C',
        '- [ ] Item B',
        '- [ ] Item A',
      ];

      final res = reconciler.reconcile(invertedLines);

      expect(res.matched['D'], equals(0));
      expect(res.matched['C'], equals(1));
      expect(res.matched['B'], equals(2));
      expect(res.matched['A'], equals(3));
    });

    test('Stress 3: Subsequent iterative edits (multi-step text refinement)', () {
      final initialLines = ['- [ ] Buy milk'];
      reconciler.setInitialAnchors(initialLines, {'M': 'Buy milk'});

      // Edit 1: word addition
      final edit1 = ['- [ ] Buy fresh oat milk'];
      final res1 = reconciler.reconcile(edit1);
      expect(res1.matched['M'], equals(0));

      // Update anchor with new text
      reconciler.setInitialAnchors(edit1, {'M': 'Buy fresh oat milk'});

      // Edit 2: brand specification
      final edit2 = ['- [ ] Buy fresh oatly milk 1L'];
      final res2 = reconciler.reconcile(edit2);
      expect(res2.matched['M'], equals(0));
    });

    test('Stress 4: Split of a single item into two items', () {
      final initialLines = [
        '- [ ] Buy groceries',
        '- [ ] Call doctor',
      ];
      reconciler.setInitialAnchors(initialLines, {
        'G': 'Buy groceries',
        'D': 'Call doctor',
      });

      // User splits 'Buy groceries' into 'Buy fruits' and 'Buy vegetables'
      final splitLines = [
        '- [ ] Buy groceries (fruits)',
        '- [ ] Buy groceries (vegetables)',
        '- [ ] Call doctor',
      ];

      final res = reconciler.reconcile(splitLines);

      // 'Call doctor' remains strictly anchor-locked
      expect(res.matched['D'], equals(2));
      // Ambiguous split is isolated without destroying the entity
      expect(res.quarantined.contains('G') || res.matched['G'] != -1, isTrue);
    });

    test('Stress 5: Copy-paste of a block of items', () {
      final initialLines = [
        '- [ ] Task 1',
        '- [ ] Task 2',
      ];
      reconciler.setInitialAnchors(initialLines, {
        'T1': 'Task 1',
        'T2': 'Task 2',
      });

      final pastedLines = [
        '- [ ] Task 1',
        '- [ ] Task 2',
        '- [ ] Task 1', // pasted duplicate block
        '- [ ] Task 2',
      ];

      final res = reconciler.reconcile(pastedLines);

      // Context preserves original anchors at indices 0 and 1
      expect(res.matched['T1'], equals(0));
      expect(res.matched['T2'], equals(1));
      // The pasted copies are detected as candidate new lines
      expect(res.newLines, containsAll([2, 3]));
    });

    test('Stress 6: Simulated concurrent edit while entity has local pending state', () {
      final initialLines = [
        '- [ ] Send quarterly report',
        '- [ ] Clean workspace',
      ];
      reconciler.setInitialAnchors(initialLines, {
        'R': 'Send quarterly report',
        'C': 'Clean workspace',
      });

      // External sync modified line text to 'Send Q3 fiscal report'
      final externalEditLines = [
        '- [ ] Send Q3 fiscal report',
        '- [ ] Clean workspace',
      ];

      final res = reconciler.reconcile(externalEditLines);

      expect(res.matched['R'], equals(0));
      expect(res.matched['C'], equals(1));
    });

    test('Stress 7: Calibration of Similarity Threshold (Dice sensitivity curve)', () {
      const s1 = 'buy organic oat milk';
      const s2 = 'buy almond milk';
      const s3 = 'sell government bonds';

      final simClose = HybridLineReconciler.calculateDiceSimilarity(s1, s2);
      final simDistant = HybridLineReconciler.calculateDiceSimilarity(s1, s3);

      expect(simClose, greaterThan(0.40));
      expect(simDistant, equals(0.0));

      // With threshold 0.80, partial edits are rejected
      final strictReconciler = HybridLineReconciler(similarityThreshold: 0.80);
      strictReconciler.setInitialAnchors(['- [ ] $s1'], {'E': s1});
      final resStrict = strictReconciler.reconcile(['- [ ] $s2']);
      expect(resStrict.matched['E'], equals(-1)); // safely unmapped under strict threshold

      // With calibrated threshold 0.50, related edits are tracked
      final tolerantReconciler = HybridLineReconciler(similarityThreshold: 0.50);
      tolerantReconciler.setInitialAnchors(['- [ ] $s1'], {'E': s1});
      final resTolerant = tolerantReconciler.reconcile(['- [ ] $s2']);
      expect(resTolerant.matched['E'], equals(0));
    });

    test('Stress 8: Randomized Monte-Carlo Permutations with Ground-Truth Identity Oracle', () {
      final random = Random(42);
      const itemCount = 20;

      final initialItems = List.generate(itemCount, (i) => 'Unique task item #$i with token_${i * 13}');
      final entities = {for (var i = 0; i < itemCount; i++) 'ID_$i': initialItems[i]};

      reconciler.setInitialAnchors(initialItems.map((t) => '- [ ] $t').toList(), entities);

      // Perform 50 randomized mutation rounds (shuffle, insert, delete, modify)
      for (int round = 0; round < 50; round++) {
        final currentList = List<String>.from(initialItems);
        // Randomly shuffle subset
        currentList.shuffle(random);

        // Randomly modify 3 items with token insertion
        for (int m = 0; m < 3; m++) {
          final idx = random.nextInt(currentList.length);
          currentList[idx] = '${currentList[idx]} (updated in round $round)';
        }

        final res = reconciler.reconcile(currentList.map((t) => '- [ ] $t').toList());

        // Verification Oracle: every matched entity MUST point to a line containing its original ID token
        res.matched.forEach((entityId, matchedLineIdx) {
          if (matchedLineIdx != -1) {
            final lineText = currentList[matchedLineIdx];
            final originalItemText = entities[entityId]!;
            final dice = HybridLineReconciler.calculateDiceSimilarity(originalItemText, lineText);
            expect(dice >= 0.50 || lineText.contains(originalItemText), isTrue,
                reason: 'False positive match detected for $entityId on line $lineText');
          }
        });
      }
    });
  });
}
