import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static const _appleApiKey = 'YOUR_APPLE_API_KEY';

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
    } catch (_) {
      return false;
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
