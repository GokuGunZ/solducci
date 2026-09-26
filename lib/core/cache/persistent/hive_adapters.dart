import 'package:hive_flutter/hive_flutter.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/user_profile.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_type.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:solducci/models/asset_price_snapshot.dart';
import 'package:solducci/models/expense_asset_allocation.dart';
import 'package:solducci/core/cache/persistent/persistent_cache_entry.dart';

/// Register all Hive type adapters
///
/// This must be called before opening any Hive boxes.
/// Typically called in main() during app initialization.
///
/// Registered adapters:
/// - PersistentCacheMetadata (typeId: 0)
/// - Expense (typeId: 1)
/// - Tipologia enum (typeId: 3)
/// - SplitType enum (typeId: 4)
/// - UserProfile (typeId: 5)
/// - ExpenseGroup (typeId: 6)
/// - GroupMember (typeId: 7)
/// - GroupRole enum (typeId: 8)
/// - Wallet (typeId: 9)
/// - WalletType enum (typeId: 10)
/// - Income (typeId: 11)
/// - IncomeCategory enum (typeId: 12)
/// - WalletTransfer (typeId: 13)
/// - InvestmentPortfolio (typeId: 14)
/// - AssetClass enum (typeId: 15)
/// - InvestmentAsset (typeId: 16)
/// - AssetPriceSnapshot (typeId: 17)
/// - ExpenseAssetAllocation (typeId: 18)
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

  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(WalletAdapter());
  }

  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(WalletTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(IncomeAdapter());
  }

  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(IncomeCategoryAdapter());
  }

  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(WalletTransferAdapter());
  }

  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(InvestmentPortfolioAdapter());
  }

  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(AssetClassAdapter());
  }

  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(InvestmentAssetAdapter());
  }

  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(AssetPriceSnapshotAdapter());
  }

  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(ExpenseAssetAllocationAdapter());
  }

  print('✅ Hive adapters registered successfully');
}
