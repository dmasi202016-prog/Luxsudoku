import 'package:hive/hive.dart';

part 'premium_status.g.dart';

/// Model for tracking user's premium status
@HiveType(typeId: 4)
class PremiumStatus extends HiveObject {
  /// Is user a premium member?
  @HiveField(0)
  bool isPremium;

  /// Purchase timestamp
  @HiveField(1)
  DateTime? purchasedAt;

  /// Purchase transaction ID (for verification)
  @HiveField(2)
  String? transactionId;

  /// Last verified timestamp
  @HiveField(3)
  DateTime? lastVerified;

  PremiumStatus({
    required this.isPremium,
    this.purchasedAt,
    this.transactionId,
    this.lastVerified,
  });

  /// Create initial status for free users
  factory PremiumStatus.free() {
    return PremiumStatus(
      isPremium: false,
      purchasedAt: null,
      transactionId: null,
      lastVerified: null,
    );
  }

  /// Create premium status after purchase
  factory PremiumStatus.premium({
    required DateTime purchasedAt,
    required String transactionId,
  }) {
    return PremiumStatus(
      isPremium: true,
      purchasedAt: purchasedAt,
      transactionId: transactionId,
      lastVerified: DateTime.now(),
    );
  }

  /// Create from JSON
  factory PremiumStatus.fromJson(Map<String, dynamic> json) {
    return PremiumStatus(
      isPremium: json['isPremium'] as bool,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'] as String)
          : null,
      transactionId: json['transactionId'] as String?,
      lastVerified: json['lastVerified'] != null
          ? DateTime.parse(json['lastVerified'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isPremium': isPremium,
      'purchasedAt': purchasedAt?.toIso8601String(),
      'transactionId': transactionId,
      'lastVerified': lastVerified?.toIso8601String(),
    };
  }

  /// Copy with new values
  PremiumStatus copyWith({
    bool? isPremium,
    DateTime? purchasedAt,
    String? transactionId,
    DateTime? lastVerified,
  }) {
    return PremiumStatus(
      isPremium: isPremium ?? this.isPremium,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      transactionId: transactionId ?? this.transactionId,
      lastVerified: lastVerified ?? this.lastVerified,
    );
  }

  @override
  String toString() {
    return 'PremiumStatus(isPremium: $isPremium, purchasedAt: $purchasedAt)';
  }
}
