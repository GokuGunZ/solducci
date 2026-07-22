import 'package:solducci/models/dashboard_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  // Singleton pattern
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final _supabase = Supabase.instance.client;

  /// Get the dashboard layout for the current user and device type
  Future<DashboardConfig?> getDashboardConfig({String deviceType = 'mobile'}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_dashboards')
          .select()
          .eq('user_id', userId)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (response != null) {
        return DashboardConfig.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching dashboard config: $e');
      return null;
    }
  }

  /// Save or update the dashboard layout
  Future<DashboardConfig?> saveDashboardConfig(DashboardConfig config) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dataToUpsert = config.toInsertMap();
      dataToUpsert['user_id'] = userId; // Ensure we always save for current user

      final response = await _supabase
          .from('user_dashboards')
          .upsert(dataToUpsert, onConflict: 'user_id, device_type')
          .select()
          .single();

      return DashboardConfig.fromMap(response);
    } catch (e) {
      print('Error saving dashboard config: $e');
      return null;
    }
  }

  /// Delete a dashboard configuration
  Future<void> deleteDashboardConfig({String deviceType = 'mobile'}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('user_dashboards')
          .delete()
          .eq('user_id', userId)
          .eq('device_type', deviceType);
    } catch (e) {
      print('Error deleting dashboard config: $e');
    }
  }
}
