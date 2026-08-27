import 'package:solducci/service/profile_service_cached.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureOnboardingService {
  static final FeatureOnboardingService _instance = FeatureOnboardingService._internal();
  factory FeatureOnboardingService() => _instance;
  FeatureOnboardingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileServiceCached _profileService = ProfileServiceCached();

  /// Check if the current user has onboarded a specific feature
  Future<bool> hasOnboarded(String featureKey) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final profile = await _profileService.fetchById(user.id);
      if (profile != null) {
        return profile.onboardedFeatures.contains(featureKey);
      }
    } catch (e) {
      print('Error checking onboarded feature: $e');
    }
    return false;
  }

  /// Mark a specific feature as onboarded for the current user
  Future<void> markAsOnboarded(String featureKey) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _profileService.fetchById(user.id);
      if (profile != null) {
        if (!profile.onboardedFeatures.contains(featureKey)) {
          // Update local profile
          profile.onboardedFeatures.add(featureKey);
          
          // Update local cache and Supabase DB
          await _supabase
              .from('profiles')
              .update({
                'onboarded_features': profile.onboardedFeatures,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', user.id);
              
          // Ensure it's cached properly
          await _profileService.updateItem(profile);
        }
      }
    } catch (e) {
      print('Error marking feature as onboarded: $e');
    }
  }

  /// Reset a specific feature onboarding for the current user (Debug/Testing)
  Future<void> resetOnboarding(String featureKey) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _profileService.fetchById(user.id);
      if (profile != null) {
        if (profile.onboardedFeatures.contains(featureKey)) {
          // Update local profile
          profile.onboardedFeatures.remove(featureKey);
          
          // Update local cache and Supabase DB
          await _supabase
              .from('profiles')
              .update({
                'onboarded_features': profile.onboardedFeatures,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', user.id);
              
          // Ensure it's cached properly
          await _profileService.updateItem(profile);
        }
      }
    } catch (e) {
      print('Error resetting feature onboarding: $e');
    }
  }
}
