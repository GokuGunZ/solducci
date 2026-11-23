import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/capabilities/capabilities.dart';

/// Database security & RLS contract simulation matching
/// supabase/migrations/20261025_create_life_os_core_schema.sql.
class DatabaseRlsSimulator {
  final Map<String, Map<String, dynamic>> documents = {};
  final Map<String, Map<String, dynamic>> tasks = {};
  final Map<String, Map<String, dynamic>> expenses = {};
  final Map<String, Map<String, dynamic>> timeScenarios = {};
  final Map<String, Map<String, dynamic>> entityRelations = {};
  final Map<String, Map<String, dynamic>> lifeSessions = {};
  final Map<String, Map<String, dynamic>> userEntityOverlays = {};
  final Map<String, Set<String>> groupMembers = {}; // groupId -> Set<userId>

  bool isGroupMember(String groupId, String userId) {
    return groupMembers[groupId]?.contains(userId) ?? false;
  }

  bool canUserReadDocument(String docId, String userId) {
    final doc = documents[docId];
    if (doc == null) return false;
    if (doc['user_id'] == userId) return true;
    final gid = doc['group_id'] as String?;
    if (gid != null && isGroupMember(gid, userId)) return true;
    return false;
  }

  bool canUserReadTarget(String targetId, String targetType, String userId) {
    switch (targetType) {
      case 'entity':
        return canUserReadDocument(targetId, userId);
      case 'task':
        final task = tasks[targetId];
        if (task == null) return false;
        final docId = task['document_id'] as String?;
        return docId != null && canUserReadDocument(docId, userId);
      case 'expense':
        final exp = expenses[targetId];
        if (exp == null) return false;
        if (exp['user_id'] == userId) return true;
        final gid = exp['group_id'] as String?;
        return gid != null && isGroupMember(gid, userId);
      case 'time_scenario':
        final ts = timeScenarios[targetId];
        if (ts == null) return false;
        final docId = ts['document_id'] as String?;
        return docId != null && canUserReadDocument(docId, userId);
      default:
        return false;
    }
  }

  // Insert entity_relation enforcing RLS policy `entity_relations_insert_policy`
  bool insertRelation({
    required String relationId,
    required String authUserId,
    required String sourceId,
    required String targetId,
    required String targetType,
    required String relationType,
    String? contextStatus,
  }) {
    // 1. User must own the relation row
    // 2. User must have read/write access to source document
    if (!canUserReadDocument(sourceId, authUserId)) {
      return false;
    }
    // 3. User must have read access to target object (Amendment C / RLS)
    if (!canUserReadTarget(targetId, targetType, authUserId)) {
      return false;
    }

    entityRelations[relationId] = {
      'id': relationId,
      'user_id': authUserId,
      'source_id': sourceId,
      'source_type': 'entity',
      'target_id': targetId,
      'target_type': targetType,
      'relation_type': relationType,
      'context_status': contextStatus,
    };
    return true;
  }

  // Trigger: Cleanup on target deletion (Amendment C)
  void deleteTargetObject(String targetId, String targetType) {
    switch (targetType) {
      case 'entity':
        documents.remove(targetId);
        break;
      case 'task':
        tasks.remove(targetId);
        break;
      case 'expense':
        expenses.remove(targetId);
        break;
      case 'time_scenario':
        timeScenarios.remove(targetId);
        break;
    }

    // Trigger `trg_cleanup_*_target` execution:
    entityRelations.removeWhere((id, rel) =>
        rel['target_id'] == targetId && rel['target_type'] == targetType);
  }

  // Insert life_session enforcing `life_sessions_insert_policy`
  bool insertSession({
    required String sessionId,
    required String authUserId,
    required String primaryEntityId,
    List<String> relatedEntityIds = const [],
    required DateTime startedAt,
    int? durationMinutes,
    int? stateEnergy,
    int? stateFocus,
    int? stateFriction,
    String? narrative,
    Map<String, dynamic> observations = const {},
    Map<String, dynamic> metrics = const {},
  }) {
    // Primary entity must be accessible to user
    if (!canUserReadDocument(primaryEntityId, authUserId)) {
      return false;
    }

    lifeSessions[sessionId] = {
      'id': sessionId,
      'user_id': authUserId,
      'primary_entity_id': primaryEntityId,
      'related_entity_ids': relatedEntityIds,
      'started_at': startedAt,
      'duration_minutes': durationMinutes,
      'state_energy': stateEnergy,
      'state_focus': stateFocus,
      'state_friction': stateFriction,
      'narrative': narrative,
      'observations': observations,
      'metrics': metrics,
    };
    return true;
  }

  // Query sessions enforcing `life_sessions_select_policy` (user_id = auth.uid())
  List<Map<String, dynamic>> selectSessionsForEntity({
    required String entityId,
    required String authUserId,
  }) {
    return lifeSessions.values.where((s) {
      final isAuthor = s['user_id'] == authUserId;
      final matchesEntity = s['primary_entity_id'] == entityId ||
          (s['related_entity_ids'] as List<String>).contains(entityId);
      return isAuthor && matchesEntity;
    }).toList();
  }

  // Set overlay enforcing `user_entity_overlays_insert_policy` / update
  bool setOverlay({
    required String authUserId,
    required String entityId,
    bool isInWeeklyRail = false,
    String commitmentWeight = 'medium',
    String? personalNotes,
  }) {
    if (!canUserReadDocument(entityId, authUserId)) {
      return false;
    }
    final key = '${entityId}_$authUserId';
    userEntityOverlays[key] = {
      'entity_id': entityId,
      'user_id': authUserId,
      'is_in_weekly_rail': isInWeeklyRail,
      'commitment_weight': commitmentWeight,
      'personal_notes': personalNotes,
    };
    return true;
  }

  // Query overlay enforcing `user_entity_overlays_select_policy`
  Map<String, dynamic>? selectOverlay({
    required String entityId,
    required String authUserId,
  }) {
    final key = '${entityId}_$authUserId';
    final overlay = userEntityOverlays[key];
    if (overlay == null || overlay['user_id'] != authUserId) {
      return null;
    }
    return overlay;
  }
}

void main() {
  const userA = 'user-alice-001';
  const userB = 'user-bob-002';
  const userC = 'user-charlie-003';
  const group1 = 'group-work-100';

  late DatabaseRlsSimulator db;

  setUp(() {
    db = DatabaseRlsSimulator();
    // Setup group membership: Alice and Bob are in group1, Charlie is not
    db.groupMembers[group1] = {userA, userB};
  });

  group('1. Personal Entity Isolation Contract', () {
    const personalDocId = 'doc-alice-personal';

    setUp(() {
      db.documents[personalDocId] = {
        'id': personalDocId,
        'user_id': userA,
        'group_id': null,
        'title': 'Alice Private Project',
        'document_type': 'life_entity',
      };
    });

    test('User A can access and relate to their personal entity', () {
      expect(db.canUserReadDocument(personalDocId, userA), isTrue);

      final success = db.insertRelation(
        relationId: 'rel-1',
        authUserId: userA,
        sourceId: personalDocId,
        targetId: personalDocId,
        targetType: 'entity',
        relationType: 'relates_to',
      );
      expect(success, isTrue);
    });

    test('User B cannot read User A personal entity', () {
      expect(db.canUserReadDocument(personalDocId, userB), isFalse);
    });

    test('User B cannot create a relation towards User A personal entity knowing UUID', () {
      // User B creates a document of their own
      const bobDocId = 'doc-bob-personal';
      db.documents[bobDocId] = {
        'id': bobDocId,
        'user_id': userB,
        'group_id': null,
        'title': 'Bob Document',
        'document_type': 'life_entity',
      };

      // User B tries to link their doc to Alice's private doc
      final relSuccess = db.insertRelation(
        relationId: 'rel-b-to-a',
        authUserId: userB,
        sourceId: bobDocId,
        targetId: personalDocId, // Alice's private doc
        targetType: 'entity',
        relationType: 'relates_to',
      );

      expect(relSuccess, isFalse,
          reason: 'RLS must reject relations pointing to unauthorized targets');
    });
  });

  group('2. Shared Entity Multi-User Contract', () {
    const sharedDocId = 'doc-shared-team';

    setUp(() {
      db.documents[sharedDocId] = {
        'id': sharedDocId,
        'user_id': userA,
        'group_id': group1,
        'title': 'Team Shared Project',
        'document_type': 'life_entity',
      };
    });

    test('Authorized group members (Alice & Bob) can read shared entity', () {
      expect(db.canUserReadDocument(sharedDocId, userA), isTrue);
      expect(db.canUserReadDocument(sharedDocId, userB), isTrue);
    });

    test('Non-member (Charlie) cannot read or link to shared entity', () {
      expect(db.canUserReadDocument(sharedDocId, userC), isFalse);

      final relSuccess = db.insertRelation(
        relationId: 'rel-charlie',
        authUserId: userC,
        sourceId: sharedDocId,
        targetId: sharedDocId,
        targetType: 'entity',
        relationType: 'relates_to',
      );
      expect(relSuccess, isFalse);
    });
  });

  group('3. Personal Overlay Strict Isolation (Amendment B)', () {
    const sharedDocId = 'doc-shared-solducci';

    setUp(() {
      db.documents[sharedDocId] = {
        'id': sharedDocId,
        'user_id': userA,
        'group_id': group1,
        'title': 'Solducci LifeOS',
        'document_type': 'life_entity',
      };
    });

    test('Alice & Bob have independent overlays on same shared entity', () {
      // Alice focuses on it this week with vital commitment
      final setA = db.setOverlay(
        authUserId: userA,
        entityId: sharedDocId,
        isInWeeklyRail: true,
        commitmentWeight: 'vital',
        personalNotes: 'Focus on shipping Step 1.1',
      );
      expect(setA, isTrue);

      // Bob does not focus on it this week
      final setB = db.setOverlay(
        authUserId: userB,
        entityId: sharedDocId,
        isInWeeklyRail: false,
        commitmentWeight: 'low',
        personalNotes: 'Reviewing next week',
      );
      expect(setB, isTrue);

      // Verify Alice reads only Alice's overlay
      final overlayA = db.selectOverlay(entityId: sharedDocId, authUserId: userA);
      expect(overlayA, isNotNull);
      expect(overlayA!['is_in_weekly_rail'], isTrue);
      expect(overlayA['commitment_weight'], equals('vital'));
      expect(overlayA['personal_notes'], equals('Focus on shipping Step 1.1'));

      // Verify Bob reads only Bob's overlay
      final overlayB = db.selectOverlay(entityId: sharedDocId, authUserId: userB);
      expect(overlayB, isNotNull);
      expect(overlayB!['is_in_weekly_rail'], isFalse);
      expect(overlayB['commitment_weight'], equals('low'));
      expect(overlayB['personal_notes'], equals('Reviewing next week'));
    });
  });

  group('4. LifeSession Intimate Privacy', () {
    const sharedDocId = 'doc-shared-solducci';

    setUp(() {
      db.documents[sharedDocId] = {
        'id': sharedDocId,
        'user_id': userA,
        'group_id': group1,
        'title': 'Solducci LifeOS',
        'document_type': 'life_entity',
      };
    });

    test('Author session remains strictly private even when entity is shared', () {
      final sessionSuccess = db.insertSession(
        sessionId: 'sess-alice-1',
        authUserId: userA,
        primaryEntityId: sharedDocId,
        startedAt: DateTime.now(),
        durationMinutes: 45,
        stateEnergy: 3,
        stateFocus: 4,
        stateFriction: 2,
        narrative: 'Private reflection: feeling tired but productive',
        observations: {'blocker': 'Context switching cost'},
        metrics: {'lines_of_code': 250},
      );
      expect(sessionSuccess, isTrue);

      // Alice queries sessions: gets 1 session
      final aliceSessions = db.selectSessionsForEntity(
        entityId: sharedDocId,
        authUserId: userA,
      );
      expect(aliceSessions.length, equals(1));
      expect(aliceSessions.first['narrative'],
          equals('Private reflection: feeling tired but productive'));

      // Bob queries sessions for the same shared entity: receives 0 sessions!
      final bobSessions = db.selectSessionsForEntity(
        entityId: sharedDocId,
        authUserId: userB,
      );
      expect(bobSessions.isEmpty, isTrue,
          reason: 'LifeSessions must never leak across group members');
    });
  });

  group('5. Typed Reference Integrity & Target Discrimination (Amendment C)', () {
    const sourceDocId = 'doc-source-project';
    const taskTargetId = 'task-101';
    const expenseTargetId = 'exp-202';

    setUp(() {
      db.documents[sourceDocId] = {
        'id': sourceDocId,
        'user_id': userA,
        'group_id': null,
        'title': 'Project A',
        'document_type': 'life_entity',
      };

      // Task linked to an accessible document
      db.tasks[taskTargetId] = {
        'id': taskTargetId,
        'document_id': sourceDocId,
        'title': 'Implement tests',
      };

      // Expense owned by User A
      db.expenses[expenseTargetId] = {
        'id': expenseTargetId,
        'user_id': userA,
        'title': 'Domain registration fee',
      };
    });

    test('Valid authorized targets succeed', () {
      final taskRel = db.insertRelation(
        relationId: 'rel-task',
        authUserId: userA,
        sourceId: sourceDocId,
        targetId: taskTargetId,
        targetType: 'task',
        relationType: 'requires',
      );
      expect(taskRel, isTrue);

      final expRel = db.insertRelation(
        relationId: 'rel-exp',
        authUserId: userA,
        sourceId: sourceDocId,
        targetId: expenseTargetId,
        targetType: 'expense',
        relationType: 'funded_by',
      );
      expect(expRel, isTrue);
    });

    test('Nonexistent target is rejected', () {
      final invalidRel = db.insertRelation(
        relationId: 'rel-invalid',
        authUserId: userA,
        sourceId: sourceDocId,
        targetId: 'non-existent-uuid',
        targetType: 'task',
        relationType: 'requires',
      );
      expect(invalidRel, isFalse);
    });

    test('Deleting target task cleans up relation with target_type discrimination', () {
      // Create relation to task
      db.insertRelation(
        relationId: 'rel-task-to-delete',
        authUserId: userA,
        sourceId: sourceDocId,
        targetId: taskTargetId,
        targetType: 'task',
        relationType: 'requires',
      );

      // Create unrelated entity relation where target_id happens to be another doc
      const anotherDocId = 'doc-other';
      db.documents[anotherDocId] = {
        'id': anotherDocId,
        'user_id': userA,
        'group_id': null,
        'title': 'Other Doc',
        'document_type': 'life_entity',
      };
      db.insertRelation(
        relationId: 'rel-doc-to-keep',
        authUserId: userA,
        sourceId: sourceDocId,
        targetId: anotherDocId,
        targetType: 'entity',
        relationType: 'relates_to',
      );

      expect(db.entityRelations.length, equals(2));

      // Trigger deletion of task target
      db.deleteTargetObject(taskTargetId, 'task');

      // The task relation is deleted, but the entity relation is preserved
      expect(db.entityRelations.containsKey('rel-task-to-delete'), isFalse);
      expect(db.entityRelations.containsKey('rel-doc-to-keep'), isTrue);
    });
  });

  group('6. Meaningful Activity Derivation & Invariant (Amendment D)', () {
    test('Meaningful activity derived from sessions and tasks, ignoring cosmetic edits', () {
      final t0 = DateTime(2026, 10, 20, 10, 0);
      final t1 = DateTime(2026, 10, 22, 14, 0); // Session
      final t2 = DateTime(2026, 10, 24, 09, 30); // Task completion
      final t3 = DateTime(2026, 10, 24, 12, 00); // Cosmetic title change

      var entity = LifeEntity(
        id: 'ent-proj-solducci',
        title: 'Solducci Project',
        semanticRole: SemanticRole.project,
        lifecycleState: LifecycleState.active,
        createdAt: t0,
        updatedAt: t0,
        lastMeaningfulActivityAt: null,
      );

      // 1. Initial capture has null lastMeaningfulActivityAt
      expect(entity.lastMeaningfulActivityAt, isNull);

      // 2. Session logged at t1 updates meaningful activity
      entity = entity.copyWith(
        lastMeaningfulActivityAt: () => t1,
        updatedAt: t1,
      );
      expect(entity.lastMeaningfulActivityAt, equals(t1));

      // 3. Task completed at t2 updates meaningful activity
      entity = entity.copyWith(
        lastMeaningfulActivityAt: () => t2,
        updatedAt: t2,
      );
      expect(entity.lastMeaningfulActivityAt, equals(t2));

      // 4. Cosmetic edit at t3 (updating title/description) updates updatedAt,
      // but leaves lastMeaningfulActivityAt STRICTLY UNCHANGED at t2.
      entity = entity.copyWith(
        title: 'Solducci LifeOS - Renamed',
        updatedAt: t3,
      );
      expect(entity.updatedAt, equals(t3));
      expect(entity.lastMeaningfulActivityAt, equals(t2),
          reason: 'Cosmetic updates must never alter meaningful activity timestamp');

      // 5. Inactive tension calculation behaves correctly
      // Testing with a simulated current time 25 days later (gentle tension)
      final gentleDate = t2.add(const Duration(days: 25));
      expect(entity.isResumeWorthy(referenceDate: gentleDate), isTrue);
      expect(entity.resumeTension(referenceDate: gentleDate), equals(ResumeTension.gentle));

      // Testing with a simulated current time 70 days later (high tension)
      final highDate = t2.add(const Duration(days: 70));
      expect(entity.isResumeWorthy(referenceDate: highDate), isTrue);
      expect(entity.resumeTension(referenceDate: highDate), equals(ResumeTension.high));
    });
  });
}
