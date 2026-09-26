import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/split_type.dart';

void main() {
  group('StagingTransaction Context & Split Tests', () {
    test('Default context is Personal (groupId == null)', () {
      final tx = StagingTransaction(
        id: 'tx_1',
        date: DateTime.now(),
        amount: 47.30,
        isIncome: false,
        rawDescription: 'PAGOBANCOMAT CONAD 47.30',
        cleanDescription: 'Conad Spesa',
        category: Tipologia.cibo,
      );

      expect(tx.groupId, isNull);
      expect(tx.isPersonal, isTrue);
      expect(tx.isGroup, isFalse);
      expect(tx.splitType, equals(SplitType.equal));
      expect(tx.customSplitData, isNull);
    });

    test('Assigning group context switches isGroup to true', () {
      final tx = StagingTransaction(
        id: 'tx_1',
        date: DateTime.now(),
        amount: 47.30,
        isIncome: false,
        rawDescription: 'PAGOBANCOMAT CONAD 47.30',
        cleanDescription: 'Conad Spesa',
        category: Tipologia.cibo,
      );

      final groupTx = tx.copyWith(groupId: 'grp_casa');
      expect(groupTx.groupId, equals('grp_casa'));
      expect(groupTx.isGroup, isTrue);
      expect(groupTx.isPersonal, isFalse);

      final backToPersonal = groupTx.copyWith(clearGroupId: true);
      expect(backToPersonal.groupId, isNull);
      expect(backToPersonal.isPersonal, isTrue);
    });

    test('2-person Cross-fader: 0.50€ steps and exact residual sum invariant', () {
      const totalAmount = 47.30;
      final steppedActiveValues = <double>[];

      // Genera valori a passi di 0.50€
      for (double step = 0.0; step <= totalAmount; step += 0.50) {
        steppedActiveValues.add(step);
      }

      for (final activeAmount in steppedActiveValues) {
        final otherAmount = double.parse((totalAmount - activeAmount).toStringAsFixed(2));
        final sum = double.parse((activeAmount + otherAmount).toStringAsFixed(2));

        expect(sum, equals(totalAmount), reason: 'Active: $activeAmount + Other: $otherAmount must equal $totalAmount');
        expect(activeAmount % 0.50, closeTo(0.0, 0.0001));
      }
    });

    test('2-person 50/50 exact split (cents precision)', () {
      const totalAmount = 47.33;
      final active = double.parse((totalAmount / 2).toStringAsFixed(2));
      final other = double.parse((totalAmount - active).toStringAsFixed(2));

      expect(active, equals(23.66));
      expect(other, equals(23.67));
      expect(active + other, equals(47.33));
    });

    test('Multi-person Mixer: exclusion and auto-balance invariant', () {
      const total = 60.00;
      final members = ['user_1', 'user_2', 'user_3', 'user_4'];
      final excluded = {'user_4'}; // User 4 is excluded (mute)

      final activeMembers = members.where((m) => !excluded.contains(m)).toList();
      expect(activeMembers.length, equals(3));

      final perPerson = total / activeMembers.length;
      final amounts = <String, double>{};
      double acc = 0.0;

      for (var i = 0; i < activeMembers.length; i++) {
        final m = activeMembers[i];
        if (i == activeMembers.length - 1) {
          amounts[m] = double.parse((total - acc).toStringAsFixed(2));
        } else {
          final val = double.parse(perPerson.toStringAsFixed(2));
          amounts[m] = val;
          acc += val;
        }
      }
      amounts['user_4'] = 0.0;

      expect(amounts['user_1'], equals(20.00));
      expect(amounts['user_2'], equals(20.00));
      expect(amounts['user_3'], equals(20.00));
      expect(amounts['user_4'], equals(0.00));

      final totalSum = amounts.values.fold(0.0, (s, a) => s + a);
      expect(totalSum, equals(60.00));
    });

    test('Batch context assignment on multiple transactions', () {
      final txList = [
        StagingTransaction(
          id: '1',
          date: DateTime.now(),
          amount: 10.0,
          isIncome: false,
          rawDescription: 'BAR',
          cleanDescription: 'Caffè',
          category: Tipologia.ristorante,
          isSelected: true,
        ),
        StagingTransaction(
          id: '2',
          date: DateTime.now(),
          amount: 55.0,
          isIncome: false,
          rawDescription: 'CONAD',
          cleanDescription: 'Spesa Conad',
          category: Tipologia.cibo,
          isSelected: true,
        ),
        StagingTransaction(
          id: '3',
          date: DateTime.now(),
          amount: 30.0,
          isIncome: false,
          rawDescription: 'AMAZON',
          cleanDescription: 'Amazon',
          category: Tipologia.tempoLibero,
          isSelected: false, // Not selected
        ),
      ];

      // Simula batch assignment su quelle selezionate
      const targetGroupId = 'group_convivenza';
      for (final tx in txList.where((t) => t.isSelected)) {
        tx.groupId = targetGroupId;
      }

      expect(txList[0].groupId, equals(targetGroupId));
      expect(txList[1].groupId, equals(targetGroupId));
      expect(txList[2].groupId, isNull); // Rimasta personale
    });
  });
}
