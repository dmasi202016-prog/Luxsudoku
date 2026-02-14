import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/monetization_constants.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/primary_button.dart';

/// Shop screen for purchasing hints and premium
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isLoading = false;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    // Skip IAP initialization on web
    if (kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    // Initialize IAP
    final initialized = await IAPService.instance.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-app purchases are not available'),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Set callbacks
    IAPService.instance.onPurchaseSuccess = _onPurchaseSuccess;
    IAPService.instance.onPurchaseError = _onPurchaseError;
    IAPService.instance.onPurchaseCancelled = _onPurchaseCancelled;

    // Load products
    _products = IAPService.instance.products;

    setState(() => _isLoading = false);
  }

  void _onPurchaseSuccess(String productId) {
    debugPrint('[ShopScreen] Purchase success: $productId');

    // Handle premium unlock
    if (productId == MonetizationConstants.premiumUnlockId) {
      ref.read(premiumStatusProvider.notifier).unlockPremium(
            transactionId: 'transaction_${DateTime.now().millisecondsSinceEpoch}',
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Premium unlocked! Ads removed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    // Handle hint packs
    else {
      int hintAmount = 0;
      if (productId == MonetizationConstants.hints5PackId) {
        hintAmount = MonetizationConstants.hints5Quantity;
      } else if (productId == MonetizationConstants.hints20PackId) {
        hintAmount = MonetizationConstants.hints20Quantity;
      } else if (productId == MonetizationConstants.hints50PackId) {
        hintAmount = MonetizationConstants.hints50Quantity;
      }

      if (hintAmount > 0) {
        ref.read(hintBalanceProvider.notifier).addHintsFromPurchase(hintAmount);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $hintAmount hints added!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _onPurchaseError(String error) {
    debugPrint('[ShopScreen] Purchase error: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPurchaseCancelled() {
    debugPrint('[ShopScreen] Purchase cancelled');
  }

  Future<void> _buyProduct(ProductDetails product) async {
    setState(() => _isLoading = true);
    await IAPService.instance.buyProduct(product);
    setState(() => _isLoading = false);
  }

  Future<void> _watchAdForHints() async {
    // Ads not available on web
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ads are not available on web. Please use mobile app.'),
        ),
      );
      return;
    }

    // Load rewarded ad if not loaded
    if (!AdService.instance.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading ad... Please try again.'),
        ),
      );
      await AdService.instance.loadRewardedAd();
      return;
    }

    // Show rewarded ad
    final rewarded = await AdService.instance.showRewardedAd();
    if (rewarded) {
      // Give hints
      await ref.read(hintBalanceProvider.notifier).addHintsFromAd(
            MonetizationConstants.hintsPerRewardedAd,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎁 ${MonetizationConstants.hintsPerRewardedAd} hint added!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final hintBalance = ref.watch(hintBalanceProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Current status
                            _buildStatusCard(isPremium, hintBalance.currentHints),
                            
                            const SizedBox(height: 24),
                            
                            // Watch ad for hints (free users only, not on web)
                            if (!isPremium && !kIsWeb) ...[
                              _buildWatchAdCard(),
                              const SizedBox(height: 24),
                            ],
                            
                            // Web notice
                            if (kIsWeb) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Web version has limited features. Install mobile app for ads and purchases.',
                                        style: TextStyle(color: Colors.orange.shade100),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Premium section
                            if (!isPremium) ...[
                              _buildSectionTitle('Premium'),
                              const SizedBox(height: 12),
                              _buildPremiumCard(),
                              const SizedBox(height: 24),
                            ],
                            
                            // Hint packs section
                            _buildSectionTitle('Hint Packs'),
                            const SizedBox(height: 12),
                            ..._buildHintPackCards(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Shop',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isPremium, int hints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? Colors.amber : AppColors.primaryColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (isPremium)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  'Premium Member',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Free Member',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
              const SizedBox(width: 8),
              Text(
                isPremium ? 'Unlimited Hints' : '$hints Hints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.play_circle_filled, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Watch Ad for Hint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get ${MonetizationConstants.hintsPerRewardedAd} hint for free!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Watch Ad',
            onPressed: _watchAdForHints,
            backgroundColor: Colors.white,
            textColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPremiumCard() {
    final product = IAPService.instance.premiumProduct;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Premium Unlock',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BenefitRow(icon: Icons.block, text: 'Remove all ads'),
              _BenefitRow(icon: Icons.all_inclusive, text: 'Unlimited hints'),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: kIsWeb
                ? 'Not available on web'
                : product != null
                    ? 'Buy for ${product.price}'
                    : 'Buy for ${MonetizationConstants.premiumPrice}',
            onPressed: kIsWeb ? null : () {
              if (product != null) {
                _buyProduct(product);
              }
            },
            backgroundColor: Colors.white,
            textColor: const Color.fromARGB(255, 206, 10, 131),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHintPackCards() {
    final products = IAPService.instance.hintPackProducts;
    
    final packs = [
      {
        'id': MonetizationConstants.hints5PackId,
        'quantity': MonetizationConstants.hints5Quantity,
        'price': MonetizationConstants.hints5Price,
      },
      {
        'id': MonetizationConstants.hints20PackId,
        'quantity': MonetizationConstants.hints20Quantity,
        'price': MonetizationConstants.hints20Price,
        'badge': 'Best Value',
      },
    ];

    return packs.map((pack) {
      final product = products.where((p) => p.id == pack['id']).firstOrNull;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${pack['quantity']} Hints',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pack['badge'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pack['badge'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product?.price ?? pack['price'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: kIsWeb ? null : () {
                  if (product != null) {
                    _buyProduct(product);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(kIsWeb ? 'N/A' : 'Buy'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
