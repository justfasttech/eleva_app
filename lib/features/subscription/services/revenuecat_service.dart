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
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
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
    } catch (e) {
      debugPrint('RevenueCat restorePurchases error: $e');
      return null;
    }
  }

  static Future<bool> hasPremiumEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive == true;
    } catch (e) {
      debugPrint('RevenueCat hasPremiumEntitlement error: $e');
      return false;
    }
  }

  static Future<String?> getManagementURL() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (e) {
      debugPrint('RevenueCat getManagementURL error: $e');
      return null;
    }
  }

  static Future<void> syncSubscriptionStatus() async {
    try {
      if (kIsWeb) {
        // No web, verificar direto no Stripe via Edge Function
        await Supabase.instance.client.functions.invoke(
          'verify-subscription',
          method: HttpMethod.post,
        );
        return;
      }

      // Mobile: usar RevenueCat como fonte de verdade
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all['premium'];
      final isActive = entitlement?.isActive == true;

      if (isActive && entitlement != null) {
        await Supabase.instance.client.from('profiles').update({
          'subscription_status': 'premium',
          'subscription_end_date': entitlement.expirationDate,
          'subscription_will_renew': entitlement.willRenew,
        }).eq('id', userId);
        return;
      }

      // RevenueCat diz inativo — verificar subscription_end_date no banco
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('subscription_end_date')
          .eq('id', userId)
          .single();

      final endDateStr = profile['subscription_end_date'] as String?;
      if (endDateStr != null) {
        final endDate = DateTime.tryParse(endDateStr);
        if (endDate != null && endDate.isAfter(DateTime.now())) {
          return;
        }
      }

      await Supabase.instance.client.from('profiles').update({
        'subscription_status': 'free',
        'subscription_period': null,
        'subscription_end_date': null,
        'subscription_will_renew': false,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('RevenueCat syncSubscriptionStatus error: $e');
    }
  }

  static Future<void> logIn(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  static Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
  }
}
