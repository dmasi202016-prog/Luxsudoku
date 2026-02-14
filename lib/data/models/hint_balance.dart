import 'package:hive/hive.dart';

part 'hint_balance.g.dart';

/// Model for tracking user's hint balance
@HiveType(typeId: 3)
class HintBalance extends HiveObject {
  /// Current available hints
  @HiveField(0)
  int currentHints;

  /// Total hints used (lifetime)
  @HiveField(1)
  int totalUsed;

  /// Total hints earned from ads
  @HiveField(2)
  int totalFromAds;

  /// Total hints purchased
  @HiveField(3)
  int totalPurchased;

  /// Last update timestamp
  @HiveField(4)
  DateTime lastUpdated;

  HintBalance({
    required this.currentHints,
    this.totalUsed = 0,
    this.totalFromAds = 0,
    this.totalPurchased = 0,
    required this.lastUpdated,
  });

  /// Create initial hint balance for new users
  factory HintBalance.initial() {
    return HintBalance(
      currentHints: 3, // Start with 3 free hints
      totalUsed: 0,
      totalFromAds: 0,
      totalPurchased: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from JSON
  factory HintBalance.fromJson(Map<String, dynamic> json) {
    return HintBalance(
      currentHints: json['currentHints'] as int,
      totalUsed: json['totalUsed'] as int? ?? 0,
      totalFromAds: json['totalFromAds'] as int? ?? 0,
      totalPurchased: json['totalPurchased'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentHints': currentHints,
      'totalUsed': totalUsed,
      'totalFromAds': totalFromAds,
      'totalPurchased': totalPurchased,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Copy with new values
  HintBalance copyWith({
    int? currentHints,
    int? totalUsed,
    int? totalFromAds,
    int? totalPurchased,
    DateTime? lastUpdated,
  }) {
    return HintBalance(
      currentHints: currentHints ?? this.currentHints,
      totalUsed: totalUsed ?? this.totalUsed,
      totalFromAds: totalFromAds ?? this.totalFromAds,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'HintBalance(current: $currentHints, used: $totalUsed, fromAds: $totalFromAds, purchased: $totalPurchased)';
  }
}
