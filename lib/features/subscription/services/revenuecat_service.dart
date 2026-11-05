import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RevenueCatService {
  static const _googleApiKey = 'goog_ZgVxLKMtEIQfGWIgfWbtHfGXpSh';
  static const _appleApiKey = 'appl_KsTRmgZkrWLsEhMRcURaxFPamvC';
  // TODO: trocar para produção antes de publicar: strp_GoShmgWbMKBGtkfeYctqVlXBkCq
  static const _webApiKey = 'strp_sb_tTTJzuVsCBpmpNKCJXtxAIEQ';

  static bool _initialized = false;

  static String get _apiKey {
    if (kIsWeb) return _webApiKey;
    if (defaultTargetPlatform == TargetPlatform.iOS) return _appleApiKey;
    return _googleApiKey;
  }

  static Future<void> init({required String userId}) async {
    if (_initialized) return;

    final configuration = PurchasesConfiguration(_apiKey)
      ..appUserID = userId;

    await Purchases.configure(configuration);
    _initialized = true;
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  static Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPremiumEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getManagementURL() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (_) {
      return null;
    }
  }

  static Future<void> syncSubscriptionStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all['premium'];
      final isActive = entitlement?.isActive == true;

      final updates = <String, dynamic>{
        'subscription_status': isActive ? 'premium' : 'free',
      };

      if (isActive && entitlement != null) {
        updates['subscription_end_date'] = entitlement.expirationDate;
      }

      if (!isActive) {
        updates['subscription_period'] = null;
        updates['subscription_end_date'] = null;
      }

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (_) {}
  }

  static Future<void> logIn(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  static Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }
}
