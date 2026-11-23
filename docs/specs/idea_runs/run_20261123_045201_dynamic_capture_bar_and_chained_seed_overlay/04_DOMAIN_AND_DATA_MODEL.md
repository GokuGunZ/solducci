# 04 — DOMAIN AND DATA MODEL SPECIFICATION

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Focus:** Domain Value Objects, Mention Tokens, Chained Relations, and Database Invariants  

---

## 1. Domain Entities & Value Objects

### A. Mention Token Model (`SeedMention`)
```dart
/// Represents an entity referenced via '@' inside a seed capture.
class SeedMention extends Equatable {
  final String entityId;
  final String entityTitle;
  final SemanticRole role;
  final RelationType relationType; // partOf vs relatesTo
  final int charStartIndex;
  final int charEndIndex;
  final bool isLeadingTag;

  const SeedMention({
    required this.entityId,
    required this.entityTitle,
    required this.role,
    required this.relationType,
    required this.charStartIndex,
    required this.charEndIndex,
    required this.isLeadingTag,
  });

  SeedMention copyWith({
    RelationType? relationType,
  }) {
    return SeedMention(
      entityId: entityId,
      entityTitle: entityTitle,
      role: role,
      relationType: relationType ?? this.relationType,
      charStartIndex: charStartIndex,
      charEndIndex: charEndIndex,
      isLeadingTag: isLeadingTag,
    );
  }

  @override
  List<Object?> get props => [
        entityId,
        entityTitle,
        role,
        relationType,
        charStartIndex,
        charEndIndex,
        isLeadingTag,
      ];
}
```

### B. Chained Capture Draft Model (`ChainedSeedNode`)
```dart
/// Represents an in-flight link in the chained capture overlay.
class ChainedSeedNode extends Equatable {
  final String seedId;
  final String text;
  final List<SeedMention> mentions;
  final String? parentSeedId;
  final int chainIndex;
  final bool isCommitted;
  final DateTime createdAt;

  const ChainedSeedNode({
    required this.seedId,
    required this.text,
    required this.mentions,
    this.parentSeedId,
    required this.chainIndex,
    required this.isCommitted,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        seedId,
        text,
        mentions,
        parentSeedId,
        chainIndex,
        isCommitted,
        createdAt,
      ];
}
```

---

## 2. Relational Graph Mapping (`entity_relations`)

When a seed is finalized in either the standard bar or the chained overlay, the system writes to the existing `documents` and `entity_relations` tables:

```text
[ Seed Document ] (documents table)
      │
      ├── [ @Mention Relation ] ──► (Tagged Entity)
      │      relation_type: 'part_of' (if leading) OR 'relates_to' (if mid-text)
      │      target_type: 'entity'
      │
      └── [ Chained Link Relation ] ──► (Preceding Seed in Chain)
             relation_type: 'part_of'
             target_type: 'entity'
             metadata: { 'chain_root_id': rootId, 'chain_depth': n }
```

### Invariant Rules (RLS & Integrity Safe):
1. **Documents First Rule (v1.06.05 Invariant):**
   The seed entity must be committed to `documents` via `LifeEntityRepository.createEntity(seed)` *before* issuing calls to `EntityRelationRepository.createRelation(relation)`. This guarantees that PostgreSQL RLS policy `EXISTS (SELECT 1 FROM documents WHERE id = source_id)` succeeds without `42501 Forbidden`.
2. **Deterministic UUIDs:**
   Client generates UUID v4 for the new seed; repository preserves it.
3. **User & Context Propagation:**
   `userId` and `groupId` from `ContextManager` or `Supabase.instance.client.auth.currentUser` are passed down to all nodes and relations in the chain.

---

## 3. Database Schema Impact: ZERO MIGRATIONS

- The existing schema from `20261025_create_life_os_core_schema.sql` completely supports:
  - Polymorphic relations (`source_type = 'entity'`, `target_type = 'entity'`).
  - Relation types `'part_of'` and `'relates_to'`.
  - Rich JSONB `metadata` on relations for chain order and mention indexing.
- **Result:** No PostgreSQL schema modifications or database migrations are required.
