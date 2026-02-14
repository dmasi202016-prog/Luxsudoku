import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../constants/monetization_constants.dart';

/// Service for managing In-App Purchases
class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isInitialized = false;
  List<ProductDetails> _products = [];
  
  /// Callbacks for purchase events
  Function(String productId)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  Function()? onPurchaseCancelled;

  /// Initialize IAP
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Check if IAP is available
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[IAPService] In-app purchases not available');
      return false;
    }

    // Note: enablePendingPurchases is no longer needed in newer versions
    // Pending purchases are automatically enabled

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        debugPrint('[IAPService] Purchase stream done');
      },
      onError: (error) {
        debugPrint('[IAPService] Purchase stream error: $error');
      },
    );

    // Load products
    await loadProducts();

    _isInitialized = true;
    debugPrint('[IAPService] IAP initialized successfully');
    return true;
  }

  /// Check if IAP is initialized
  bool get isInitialized => _isInitialized;

  // ============================================================
  // Products
  // ============================================================

  /// Load all products from store
  Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(
        MonetizationConstants.allProductIds.toSet(),
      );

      if (response.error != null) {
        debugPrint('[IAPService] Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('[IAPService] Loaded ${_products.length} products');
      
      for (final product in _products) {
        debugPrint(
          '[IAPService] Product: ${product.id} - ${product.title} - ${product.price}',
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAPService] Products not found: ${response.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('[IAPService] Error loading products: $e');
    }
  }

  /// Get all available products
  List<ProductDetails> get products => _products;

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get premium product
  ProductDetails? get premiumProduct =>
      getProduct(MonetizationConstants.premiumUnlockId);

  /// Get hint pack products
  List<ProductDetails> get hintPackProducts {
    return [
      getProduct(MonetizationConstants.hints5PackId),
      getProduct(MonetizationConstants.hints20PackId),
      getProduct(MonetizationConstants.hints50PackId),
    ].whereType<ProductDetails>().toList();
  }

  // ============================================================
  // Purchase
  // ============================================================

  /// Purchase a product
  Future<void> buyProduct(ProductDetails product) async {
    if (!_isInitialized) {
      debugPrint('[IAPService] IAP not initialized');
      onPurchaseError?.call('IAP not initialized');
      return;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      
      // Determine if consumable or non-consumable
      final isConsumable = product.id != MonetizationConstants.premiumUnlockId;
      
      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      
      debugPrint('[IAPService] Purchase initiated for ${product.id}');
    } catch (e) {
      debugPrint('[IAPService] Error purchasing product: $e');
      onPurchaseError?.call(e.toString());
    }
  }

  /// Restore purchases (iOS)
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      debugPrint('[IAPService] IAP not initialized');
      return;
    }

    try {
      await _iap.restorePurchases();
      debugPrint('[IAPService] Restore purchases initiated');
    } catch (e) {
      debugPrint('[IAPService] Error restoring purchases: $e');
      onPurchaseError?.call('Failed to restore purchases');
    }
  }

  // ============================================================
  // Purchase Update Handler
  // ============================================================

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
        '[IAPService] Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePending(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
          _handlePurchased(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          _handleRestored(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handleError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceled(purchaseDetails);
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  void _handlePending(PurchaseDetails purchaseDetails) {
    debugPrint('[IAPService] Purchase pending: ${purchaseDetails.productID}');
  }

  void _handlePurchased(PurchaseDetails purchaseDetails) {
    debugPrint('[IAPService] Purchase completed: ${purchaseDetails.productID}');
    
    // Verify purchase (you should verify with your backend in production)
    if (_verifyPurchase(purchaseDetails)) {
      onPurchaseSuccess?.call(purchaseDetails.productID);
    } else {
      debugPrint('[IAPService] Purchase verification failed');
      onPurchaseError?.call('Purchase verification failed');
    }
  }

  void _handleRestored(PurchaseDetails purchaseDetails) {
    debugPrint('[IAPService] Purchase restored: ${purchaseDetails.productID}');
    
    if (_verifyPurchase(purchaseDetails)) {
      onPurchaseSuccess?.call(purchaseDetails.productID);
    }
  }

  void _handleError(PurchaseDetails purchaseDetails) {
    debugPrint('[IAPService] Purchase error: ${purchaseDetails.error}');
    onPurchaseError?.call(purchaseDetails.error?.message ?? 'Purchase failed');
  }

  void _handleCanceled(PurchaseDetails purchaseDetails) {
    debugPrint('[IAPService] Purchase canceled: ${purchaseDetails.productID}');
    onPurchaseCancelled?.call();
  }

  /// Verify purchase (basic validation)
  /// In production, you should verify with your backend server
  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    // TODO: Implement server-side verification in production
    return purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored;
  }

  // ============================================================
  // Cleanup
  // ============================================================

  /// Dispose IAP service
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('[IAPService] IAP service disposed');
  }
}
