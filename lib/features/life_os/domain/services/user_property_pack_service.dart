import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';

/// User-specific preferences service for customizing Role Property Pack templates.
/// Preserves the fundamental domain invariant that pack suggestions are USER-SPECIFIC
/// and decoupled from intrinsic shared entity data.
class UserPropertyPackService {
  static const String _prefPrefix = 'life_os_role_packs_';

  // In-memory cache for fast sync access during builds
  final Map<SemanticRole, List<PropertyTemplate>> _memoryCache = {};

  /// Retrieves the customized or default property templates for a specific [role].
  Future<List<PropertyTemplate>> getTemplatesForRole(
    SemanticRole role, {
    String? userId,
  }) async {
    if (_memoryCache.containsKey(role)) {
      return List.unmodifiable(_memoryCache[role]!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${userId ?? "default"}_${role.value}';
      final rawJson = prefs.getString(storageKey);
      if (rawJson != null) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        final list = decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return PropertyTemplate(
            key: map['key'] as String? ?? 'custom',
            label: map['label'] as String? ?? '',
            placeholder: map['placeholder'] as String? ?? '',
            defaultType: PropertyType.values.firstWhere(
              (t) => t.name == map['type'],
              orElse: () => PropertyType.text,
            ),
          );
        }).toList();
        _memoryCache[role] = list;
        return List.unmodifiable(list);
      }
    } catch (_) {}

    // Fallback to domain defaults
    final defaults = RolePropertyPacks.getSuggestionsForRole(role);
    _memoryCache[role] = List.from(defaults);
    return List.unmodifiable(defaults);
  }

  /// Synchronous getter returning cached or default templates immediately.
  List<PropertyTemplate> getCachedTemplatesForRole(SemanticRole role) {
    if (_memoryCache.containsKey(role)) {
      return List.unmodifiable(_memoryCache[role]!);
    }
    return RolePropertyPacks.getSuggestionsForRole(role);
  }

  /// Saves customized property templates for a given [role].
  Future<void> saveTemplatesForRole(
    SemanticRole role,
    List<PropertyTemplate> templates, {
    String? userId,
  }) async {
    _memoryCache[role] = List.from(templates);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${userId ?? "default"}_${role.value}';
      final encoded = jsonEncode(templates
          .map((t) => {
                'key': t.key,
                'label': t.label,
                'placeholder': t.placeholder,
                'type': t.defaultType.name,
              })
          .toList());
      await prefs.setString(storageKey, encoded);
    } catch (_) {}
  }

  /// Resets a specific role pack to system defaults.
  Future<void> resetToDefaults(SemanticRole role, {String? userId}) async {
    _memoryCache.remove(role);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${userId ?? "default"}_${role.value}';
      await prefs.remove(storageKey);
    } catch (_) {}
    _memoryCache[role] = List.from(RolePropertyPacks.getSuggestionsForRole(role));
  }

  /// Resets all roles to system defaults.
  Future<void> resetAllToDefaults({String? userId}) async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final role in SemanticRole.values) {
        final storageKey = '$_prefPrefix${userId ?? "default"}_${role.value}';
        await prefs.remove(storageKey);
      }
    } catch (_) {}
  }
}
