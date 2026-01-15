import 'package:hive_flutter/hive_flutter.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/core/cache/persistent/persistent_cache_entry.dart';

/// Register all Hive type adapters
///
/// This must be called before opening any Hive boxes.
/// Typically called in main() during app initialization.
///
/// Registered adapters:
/// - PersistentCacheMetadata (typeId: 0)
/// - Expense (typeId: 1)
/// - MoneyFlow enum (typeId: 2)
/// - Tipologia enum (typeId: 3)
/// - SplitType enum (typeId: 4)
/// - UserProfile (typeId: 5)
/// - ExpenseGroup (typeId: 6)
/// - GroupMember (typeId: 7)
/// - GroupRole enum (typeId: 8)
Future<void> registerHiveAdapters() async {
  // Initialize Hive
  await Hive.initFlutter();

  print('📦 Registering Hive type adapters...');

  // Register cache metadata adapter
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PersistentCacheMetadataAdapter());
  }

  // Register model adapters
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  // Register enum adapters
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MoneyFlowAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TipologiaAdapter());
  }

  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(SplitTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(UserProfileAdapter());
  }

  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(ExpenseGroupAdapter());
  }

  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(GroupMemberAdapter());
  }

  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(GroupRoleAdapter());
  }

  print('✅ Hive adapters registered successfully');
}
