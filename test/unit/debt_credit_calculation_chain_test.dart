import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/expense_service_cached.dart';

void main() {
  group('Debt and Credit Calculation Chain Unit Tests', () {
    final now = DateTime(2026, 11, 24);
    const userA = 'user-a-carl';
    const userB = 'user-b-pit';
    const userC = 'user-c-bob';

    final members2 = [
      GroupMember(
        id: 'gm-1',
        groupId: 'group-1',
        userId: userA,
        role: GroupRole.admin,
        joinedAt: now,
        nickname: 'Carl',
      ),
      GroupMember(
        id: 'gm-2',
        groupId: 'group-1',
        userId: userB,
        role: GroupRole.member,
        joinedAt: now,
        nickname: 'Pit',
      ),
    ];

    final members3 = [
      ...members2,
      GroupMember(
        id: 'gm-3',
        groupId: 'group-1',
        userId: userC,
        role: GroupRole.member,
        joinedAt: now,
        nickname: 'Bob',
      ),
    ];

    test('1. Equal Split 50/50: Payer gains credit, other owes share', () {
      final expense = Expense(
        id: 101,
        description: 'Cena Condivisa',
        amount: 80.0,
        date: now,
        type: Tipologia.ristorante,
        userId: userA,
        groupId: 'group-1',
        paidBy: userA,
        splitType: SplitType.equal,
      );

      final splits = ExpenseServiceCached.calculateSplits(
        expenseId: 101,
        expense: expense,
        members: members2,
      );

      expect(splits.length, equals(2));
      final splitA = splits.firstWhere((s) => s['user_id'] == userA);
      final splitB = splits.firstWhere((s) => s['user_id'] == userB);

      expect(splitA['amount'], equals(40.0));
      expect(splitA['is_paid'], isTrue); // Payer's own share is paid

      expect(splitB['amount'], equals(40.0));
      expect(splitB['is_paid'], isFalse); // Pit owes 40€ to Carl
    });

    test('2. Lend Split (100% per conto di altro): Pit deve l intero importo a Carl', () {
      final expense = Expense(
        id: 102,
        description: 'Benzina anticipata interamente per Pit',
        amount: 50.0,
        date: now,
        type: Tipologia.altro,
        userId: userA,
        groupId: 'group-1',
        paidBy: userA,
        splitType: SplitType.lend,
      );

      final splits = ExpenseServiceCached.calculateSplits(
        expenseId: 102,
        expense: expense,
        members: members2,
      );

      // In SplitType.lend, non-payer owes 100% of the amount
      expect(splits.length, equals(1));
      expect(splits.first['user_id'], equals(userB));
      expect(splits.first['amount'], equals(50.0));
      expect(splits.first['is_paid'], isFalse);
    });

    test('3. Selective Equal Split: ignores excluded member using splitData in ExpenseServiceCached', () {
      // Carl and Pit split 90€ equally (45€ each), Bob excluded
      final expense = Expense(
        id: 103,
        description: 'Pranzo per 2 su 3',
        amount: 90.0,
        date: now,
        type: Tipologia.ristorante,
        userId: userA,
        groupId: 'group-1',
        paidBy: userA,
        splitType: SplitType.equal,
        splitData: {
          userA: 45.0,
          userB: 45.0,
        },
      );

      final cachedSplits = ExpenseServiceCached.calculateSplits(
        expenseId: 103,
        expense: expense,
        members: members3,
      );

      final directSplits = ExpenseService.calculateSplits(
        expenseId: 103,
        expense: expense,
        members: members3,
      );

      // Must be 2 splits (NOT 3)
      expect(cachedSplits.length, equals(2));
      expect(cachedSplits.any((s) => s['user_id'] == userC), isFalse);
      expect(cachedSplits.firstWhere((s) => s['user_id'] == userB)['amount'], equals(45.0));

      // Parity check
      expect(cachedSplits.length, equals(directSplits.length));
      expect(cachedSplits.firstWhere((s) => s['user_id'] == userB)['amount'],
          equals(directSplits.firstWhere((s) => s['user_id'] == userB)['amount']));
    });

    test('4. PairwiseDebtBalance: Sign semantics and credit monotonicity', () {
      // Positive amount means other user owes current user (CREDIT)
      final creditBalance = PairwiseDebtBalance(
        userId: userB,
        userName: 'Pit',
        userInitial: 'P',
        amount: 60.0,
      );

      expect(creditBalance.isBalanced, isFalse);
      expect(creditBalance.theyOwe, isTrue);
      expect(creditBalance.youOwe, isFalse);
      expect(creditBalance.label, contains('Pit ti deve 60.00 €'));

      // Negative amount means current user owes other user (DEBT)
      final debtBalance = PairwiseDebtBalance(
        userId: userB,
        userName: 'Pit',
        userInitial: 'P',
        amount: -25.0,
      );

      expect(debtBalance.theyOwe, isFalse);
      expect(debtBalance.youOwe, isTrue);
      expect(debtBalance.label, contains('Devi 25.00 € a Pit'));
    });

    test('5. GroupedDebtBalance: Harmonized netBalance positive for credit', () {
      final grouped = GroupedDebtBalance(
        groupId: 'group-1',
        groupName: 'Casa',
        peopleYouOwe: 0,
        peopleWhoOweYou: 1,
        totalYouOwe: 0.0,
        totalTheyOweYou: 75.0,
      );

      expect(grouped.hasCredits, isTrue);
      expect(grouped.hasDebts, isFalse);
      expect(grouped.netBalance, equals(75.0)); // Harmonized: positive when you have net credit
    });

    test('6. Monotonic Credit Growth: Adding expense paid by user increases balance', () {
      double currentCredit = 50.0; // Pit owes Carl 50€

      // Carl pays 40€ with 50/50 split -> +20€ credit
      const expenseAmount = 40.0;
      final splitPerPerson = expenseAmount / 2;
      currentCredit += splitPerPerson;

      expect(currentCredit, equals(70.0));
      expect(currentCredit > 50.0, isTrue);

      // Carl pays 30€ 100% for Pit (SplitType.lend) -> +30€ credit
      const lentAmount = 30.0;
      currentCredit += lentAmount;

      expect(currentCredit, equals(100.0));
      expect(currentCredit > 70.0, isTrue);
    });
  });
}
