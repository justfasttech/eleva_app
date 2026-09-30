import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _googleApiKey = 'goog_ZgVxLKMtEIQfGWIgfWbtHfGXpSh';
  static const _appleApiKey = 'appl_KsTRmgZkrWLsEhMRcURaxFPamvC';

  static bool _initialized = false;

  static Future<void> init({required String userId}) async {
    if (kIsWeb || _initialized) return;

    final configuration = PurchasesConfiguration(
      defaultTargetPlatform == TargetPlatform.iOS
          ? _appleApiKey
          : _googleApiKey,
    )..appUserID = userId;

    await Purchases.configure(configuration);
    _initialized = true;
  }

  static Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
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
    if (kIsWeb) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPremiumEntitlement() async {
    if (kIsWeb) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logIn(String userId) async {
    if (kIsWeb || !_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  static Future<void> logOut() async {
    if (kIsWeb || !_initialized) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }
}
