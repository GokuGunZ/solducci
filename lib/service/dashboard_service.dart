import 'package:flutter/foundation.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/cache/bento_data_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  // Singleton pattern
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final _supabase = Supabase.instance.client;

  /// Get the cached dashboard layout from local memory/disk (0ms latency)
  Future<DashboardConfig?> getCachedDashboardConfig({String deviceType = 'mobile'}) async {
    try {
      final cached = await BentoDataCache.getSnapshot('dash_cfg_$deviceType');
      if (cached != null) {
        return DashboardConfig.fromMap(cached);
      }
    } catch (e) {
      debugPrint('[DashboardService] Cache read error: $e');
    }
    return null;
  }

  /// Get the dashboard layout for the current user and device type with offline fallback
  Future<DashboardConfig?> getDashboardConfig({String deviceType = 'mobile'}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return getCachedDashboardConfig(deviceType: deviceType);
    }

    try {
      final response = await _supabase
          .from('user_dashboards')
          .select()
          .eq('user_id', userId)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (response != null) {
        final config = DashboardConfig.fromMap(response);
        // Persist to local cache for offline usage
        await BentoDataCache.saveSnapshot('dash_cfg_$deviceType', response);
        return config;
      }
      return await getCachedDashboardConfig(deviceType: deviceType);
    } catch (e) {
      debugPrint('[DashboardService] Network fetch error, using cache fallback: $e');
      return await getCachedDashboardConfig(deviceType: deviceType);
    }
  }

  /// Save or update the dashboard layout with immediate local cache write
  Future<DashboardConfig?> saveDashboardConfig(DashboardConfig config) async {
    final dataToSave = config.toInsertMap();
    final deviceType = config.deviceType;

    // 1. Instant local persistence in BentoDataCache
    await BentoDataCache.saveSnapshot('dash_cfg_$deviceType', dataToSave);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return config;

    // 2. Cloud upsert
    try {
      dataToSave['user_id'] = userId;
      final response = await _supabase
          .from('user_dashboards')
          .upsert(dataToSave, onConflict: 'user_id, device_type')
          .select()
          .single();

      return DashboardConfig.fromMap(response);
    } catch (e) {
      debugPrint('[DashboardService] Cloud save failed, cached locally: $e');
      return config;
    }
  }

  /// Delete a dashboard configuration
  Future<void> deleteDashboardConfig({String deviceType = 'mobile'}) async {
    final userId = _supabase.auth.currentUser?.id;
    try {
      await BentoDataCache.saveSnapshot('dash_cfg_$deviceType', {});
    } catch (_) {}

    if (userId == null) return;

    try {
      await _supabase
          .from('user_dashboards')
          .delete()
          .eq('user_id', userId)
          .eq('device_type', deviceType);
    } catch (e) {
      debugPrint('[DashboardService] Error deleting dashboard config: $e');
    }
  }
}
