import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/routine.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_type.dart';
import 'package:solducci/service/context_manager.dart';

void main() {
  group('Context Isolation Contract Tests (DirectContextBound)', () {
    const userA = 'user-aaa';
    const userB = 'user-bbb';
    const group1 = 'group-111';
    const group2 = 'group-222';

    final expGroup1 = ExpenseGroup(
      id: group1,
      name: 'Group 1',
      createdBy: userA,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final expGroup2 = ExpenseGroup(
      id: group2,
      name: 'Group 2',
      createdBy: userA,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final personalContextA = ExpenseContext.personal();
    final groupContext1 = ExpenseContext.group(expGroup1);
    final groupContext2 = ExpenseContext.group(expGroup2);

    final multiGroupViewWithPersonal = ExpenseContext.view(ExpenseView(
      id: 'view-1',
      name: 'Multi View All',
      groupIds: [group1],
      groups: [expGroup1],
      includePersonal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final multiGroupViewNoPersonal = ExpenseContext.view(ExpenseView(
      id: 'view-2',
      name: 'Multi View Groups Only',
      groupIds: [group1],
      groups: [expGroup1],
      includePersonal: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    test('Personal item belongs ONLY to personal context of same user', () {
      final personalIncome = Income(
        id: 'inc-1',
        userId: userA,
        amount: 100,
        description: 'Personal salary',
        date: DateTime.now(),
        category: IncomeCategory.stipendio,
      );

      // In personal context with same user
      expect(personalIncome.belongsToContext(personalContextA, currentUserId: userA), isTrue);
      // In personal context with different user
      expect(personalIncome.belongsToContext(personalContextA, currentUserId: userB), isFalse);
      // In group context
      expect(personalIncome.belongsToContext(groupContext1, currentUserId: userA), isFalse);
    });

    test('Group item belongs ONLY to matching group context', () {
      final groupIncome = Income(
        id: 'inc-2',
        userId: userA,
        groupId: group1,
        amount: 50,
        description: 'Group income',
        date: DateTime.now(),
        category: IncomeCategory.altro,
      );

      // In matching group context
      expect(groupIncome.belongsToContext(groupContext1, currentUserId: userA), isTrue);
      expect(groupIncome.belongsToContext(groupContext1, currentUserId: userB), isTrue);
      // In personal context
      expect(groupIncome.belongsToContext(personalContextA, currentUserId: userA), isFalse);
      // In different group context
      expect(groupIncome.belongsToContext(groupContext2, currentUserId: userA), isFalse);
    });

    test('Multi-group view rules are strictly enforced', () {
      final personalIncomeA = Income(
        id: 'inc-1',
        userId: userA,
        amount: 100,
        description: 'Personal salary',
        date: DateTime.now(),
        category: IncomeCategory.stipendio,
      );
      final group1Income = Income(
        id: 'inc-2',
        userId: userA,
        groupId: group1,
        amount: 50,
        description: 'Group 1 income',
        date: DateTime.now(),
        category: IncomeCategory.altro,
      );
      final group2Income = Income(
        id: 'inc-3',
        userId: userA,
        groupId: group2,
        amount: 50,
        description: 'Group 2 income',
        date: DateTime.now(),
        category: IncomeCategory.altro,
      );

      // View with includePersonal = true
      expect(personalIncomeA.belongsToContext(multiGroupViewWithPersonal, currentUserId: userA), isTrue);
      expect(group1Income.belongsToContext(multiGroupViewWithPersonal, currentUserId: userA), isTrue);
      expect(group2Income.belongsToContext(multiGroupViewWithPersonal, currentUserId: userA), isFalse);

      // View with includePersonal = false
      expect(personalIncomeA.belongsToContext(multiGroupViewNoPersonal, currentUserId: userA), isFalse);
      expect(group1Income.belongsToContext(multiGroupViewNoPersonal, currentUserId: userA), isTrue);
      expect(group2Income.belongsToContext(multiGroupViewNoPersonal, currentUserId: userA), isFalse);
    });
  });

  group('Shared Wallets and Incomes Model Serialization Tests', () {
    test('Wallet with groupId correctly serializes and deserializes', () {
      final wallet = Wallet(
        id: 'w-group-1',
        userId: 'user-1',
        groupId: 'group-xyz',
        name: 'Shared Family Account',
        type: WalletType.bank,
        initialBalance: 1500.0,
        colorHex: '#4CAF50',
        iconName: 'account_balance',
        isDefault: false,
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = wallet.toMap();
      expect(map['group_id'], 'group-xyz');
      expect(map['name'], 'Shared Family Account');

      final fromMap = Wallet.fromMap(map);
      expect(fromMap.id, 'w-group-1');
      expect(fromMap.groupId, 'group-xyz');
      expect(fromMap.isGroupContext, isTrue);
      expect(fromMap.isPersonalContext, isFalse);
    });

    test('Income with groupId correctly serializes and deserializes', () {
      final income = Income(
        id: 'inc-grp-1',
        userId: 'user-1',
        groupId: 'group-xyz',
        amount: 500.0,
        description: 'Shared refund',
        date: DateTime.now(),
        category: IncomeCategory.rimborso,
      );

      final map = income.toMap();
      expect(map['group_id'], 'group-xyz');
      expect(map['amount'], 500.0);

      final fromMap = Income.fromMap(map);
      expect(fromMap.id, 'inc-grp-1');
      expect(fromMap.groupId, 'group-xyz');
      expect(fromMap.isGroupContext, isTrue);
      expect(fromMap.isPersonalContext, isFalse);
    });

    test('RoutineTemplate with groupId correctly serializes and deserializes', () {
      final routine = RoutineTemplate(
        id: 'rt-1',
        userId: 'user-1',
        groupId: 'group-xyz',
        name: 'Turni Pulizie',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = routine.toMap();
      expect(map['group_id'], 'group-xyz');
      expect(map['name'], 'Turni Pulizie');

      final fromMap = RoutineTemplate.fromMap(map);
      expect(fromMap.groupId, 'group-xyz');
      expect(fromMap.isGroupContext, isTrue);
      expect(fromMap.isPersonalContext, isFalse);
    });
  });
}
