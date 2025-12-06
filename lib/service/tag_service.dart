import 'package:solducci/models/tag.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing tags with hierarchical support
/// Tags can be organized in parent-child relationships forming a tree structure
class TagService {
  // Singleton pattern
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  final _supabase = Supabase.instance.client;

  /// Get real-time stream of all user's tags with hierarchy built
  Stream<List<Tag>> get stream {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('tags')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name')
        .map((data) => _buildTagTree(data));
  }

  /// Get flat list of tags (without hierarchy structure)
  Stream<List<Tag>> get flatStream {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('tags')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name')
        .map((data) => _parseTags(data));
  }

  /// Get a single tag by ID
  Future<Tag?> getTagById(String tagId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('tags')
          .select()
          .eq('id', tagId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return Tag.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Get root tags (tags without parent)
  Future<List<Tag>> getRootTags() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tags')
          .select()
          .eq('user_id', userId)
          .isFilter('parent_tag_id', null)
          .order('name');

      return _parseTags(response);
    } catch (e) {
      return [];
    }
  }

  /// Get child tags of a specific parent tag
  Future<List<Tag>> getChildTags(String parentTagId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tags')
          .select()
          .eq('user_id', userId)
          .eq('parent_tag_id', parentTagId)
          .order('name');

      return _parseTags(response);
    } catch (e) {
      return [];
    }
  }

  /// Get full path of a tag (e.g., "Work > Projects > Client X")
  Future<String> getTagPath(String tagId) async {
    final tag = await getTagById(tagId);
    if (tag == null) return '';

    if (tag.parentTagId == null) {
      return tag.name;
    }

    final parentPath = await getTagPath(tag.parentTagId!);
    return '$parentPath > ${tag.name}';
  }

  /// Get all ancestor tags (parent, grandparent, etc.)
  Future<List<Tag>> getAncestorTags(String tagId) async {
    final ancestors = <Tag>[];
    String? currentId = tagId;

    while (currentId != null) {
      final tag = await getTagById(currentId);
      if (tag == null) break;

      if (tag.parentTagId != null) {
        final parent = await getTagById(tag.parentTagId!);
        if (parent != null) {
          ancestors.insert(0, parent); // Insert at beginning for correct order
        }
      }

      currentId = tag.parentTagId;
    }

    return ancestors;
  }

  /// Get all descendant tags (children, grandchildren, etc.)
  Future<List<Tag>> getDescendantTags(String tagId) async {
    final descendants = <Tag>[];
    final children = await getChildTags(tagId);

    for (final child in children) {
      descendants.add(child);
      final grandchildren = await getDescendantTags(child.id);
      descendants.addAll(grandchildren);
    }

    return descendants;
  }

  /// Create a new tag
  Future<Tag> createTag(Tag tag) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify parent tag exists if specified
      if (tag.parentTagId != null) {
        final parent = await getTagById(tag.parentTagId!);
        if (parent == null) {
          throw Exception('Parent tag not found');
        }
      }

      final dataToInsert = tag.toInsertMap();
      dataToInsert['user_id'] = userId;

      final response = await _supabase
          .from('tags')
          .insert(dataToInsert)
          .select()
          .single();

      return Tag.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing tag
  Future<void> updateTag(Tag tag) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership
      if (tag.userId != userId) {
        throw Exception('Cannot update tag owned by another user');
      }

      // Prevent circular reference in hierarchy
      if (tag.parentTagId != null) {
        final descendants = await getDescendantTags(tag.id);
        final descendantIds = descendants.map((t) => t.id).toSet();
        if (descendantIds.contains(tag.parentTagId)) {
          throw Exception('Cannot set parent to a descendant tag (circular reference)');
        }
      }

      final dataToUpdate = tag.toUpdateMap();

      await _supabase
          .from('tags')
          .update(dataToUpdate)
          .eq('id', tag.id)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a tag
  /// Note: This will set parent_tag_id to null for child tags (via ON DELETE SET NULL)
  Future<void> deleteTag(String tagId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('tags')
          .delete()
          .eq('id', tagId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Search tags by name
  Future<List<Tag>> searchTags(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tags')
          .select()
          .eq('user_id', userId)
          .ilike('name', '%$query%')
          .order('name');

      return _parseTags(response);
    } catch (e) {
      return [];
    }
  }

  /// Get tags by color
  Future<List<Tag>> getTagsByColor(String color) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tags')
          .select()
          .eq('user_id', userId)
          .eq('color', color)
          .order('name');

      return _parseTags(response);
    } catch (e) {
      return [];
    }
  }

  /// Get tags with advanced states enabled
  Future<List<Tag>> getTagsWithAdvancedStates() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tags')
          .select()
          .eq('user_id', userId)
          .eq('use_advanced_states', true)
          .order('name');

      return _parseTags(response);
    } catch (e) {
      return [];
    }
  }

  /// Build tag tree structure from flat list
  /// Returns only root tags with childTags populated recursively
  List<Tag> _buildTagTree(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    // Parse all tags
    final allTags = _parseTags(data);

    // Create a map for quick lookup
    final tagMap = <String, Tag>{};
    for (final tag in allTags) {
      tagMap[tag.id] = tag;
    }

    // Build tree by assigning children to parents
    final rootTags = <Tag>[];

    for (final tag in allTags) {
      if (tag.parentTagId == null) {
        // Root tag
        rootTags.add(tag);
      } else {
        // Child tag - add to parent's childTags
        final parent = tagMap[tag.parentTagId];
        if (parent != null) {
          parent.childTags ??= [];
          parent.childTags!.add(tag);
        } else {
          // Parent not found, treat as root (orphaned)
          rootTags.add(tag);
        }
      }
    }

    // Sort children recursively
    void sortChildren(Tag tag) {
      if (tag.childTags != null && tag.childTags!.isNotEmpty) {
        tag.childTags!.sort((a, b) => a.name.compareTo(b.name));
        for (final child in tag.childTags!) {
          sortChildren(child);
        }
      }
    }

    for (final root in rootTags) {
      sortChildren(root);
    }

    return rootTags;
  }

  /// Parse list of tag maps to Tag objects (flat, no hierarchy)
  List<Tag> _parseTags(List<Map<String, dynamic>> data) {
    final tags = <Tag>[];
    for (final map in data) {
      try {
        tags.add(Tag.fromMap(map));
      } catch (e) {
        // Skip tags that fail to parse
      }
    }
    return tags;
  }

  /// Flatten a tag tree into a list (for display purposes)
  List<Tag> flattenTagTree(List<Tag> rootTags) {
    final flattened = <Tag>[];

    void addTagAndChildren(Tag tag, int depth) {
      flattened.add(tag);
      if (tag.childTags != null) {
        for (final child in tag.childTags!) {
          addTagAndChildren(child, depth + 1);
        }
      }
    }

    for (final root in rootTags) {
      addTagAndChildren(root, 0);
    }

    return flattened;
  }

  /// Get depth level of a tag in the hierarchy (0 = root)
  Future<int> getTagDepth(String tagId) async {
    int depth = 0;
    String? currentId = tagId;

    while (currentId != null) {
      final tag = await getTagById(currentId);
      if (tag == null) break;

      if (tag.parentTagId != null) {
        depth++;
      }

      currentId = tag.parentTagId;
    }

    return depth;
  }
}
