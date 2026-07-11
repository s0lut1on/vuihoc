import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Source of truth: math-app/pricing.json (synced to assets/pricing.json at build time).
///
/// Single source → both the marketing site (Astro, build-time import) and the Flutter
/// app (rootBundle.loadString) read from the same JSON file.
class PricingConfig {
  PricingConfig._(this._data);

  final Map<String, dynamic> _data;
  static PricingConfig? _instance;

  /// Load + parse the JSON. Call once at app startup (from main()).
  static Future<PricingConfig> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/pricing.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _instance = PricingConfig._(json);
    return _instance!;
  }

  /// Synchronous access — returns the already-loaded instance, or a stub if not yet loaded.
  /// Use this in build() methods.
  static PricingConfig get instance {
    _instance ??= PricingConfig._({});
    return _instance!;
  }

  int get version => (_data['version'] as int?) ?? 0;
  String get currency => (_data['currency'] as String?) ?? 'VND';
  String get contactEmail => (_data['contact_email'] as String?) ?? 'contact@sekklings.com';

  List<Map<String, dynamic>> get tiers =>
      ((_data['tiers'] as List?) ?? const []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get compareRows =>
      ((_data['compare_rows'] as List?) ?? const []).cast<Map<String, dynamic>>();

  /// Tier by id (e.g. 'free', 'premium_monthly', 'premium_yearly').
  Map<String, dynamic>? tierById(String id) {
    for (final t in tiers) {
      if (t['id'] == id) return t;
    }
    return null;
  }

  /// Feature text in the given locale, falls back to other locale.
  String featureText(Map<String, dynamic> feature, bool en) {
    return (feature[en ? 'text_en' : 'text_vi'] as String?) ??
        (feature['text_vi'] as String? ?? '');
  }

  /// Tier name in the given locale, falls back to other locale.
  String tierName(Map<String, dynamic> tier, bool en) {
    return (tier[en ? 'name_en' : 'name_vi'] as String?) ??
        (tier['name_vi'] as String? ?? '');
  }

  /// Price period string ('/ tháng', '/ year').
  String pricePeriod(Map<String, dynamic> tier, bool en) {
    return (tier[en ? 'price_period_en' : 'price_period_vi'] as String?) ??
        (tier['price_period_vi'] as String? ?? '');
  }

  /// Format price for display.
  /// vi: 199000 → "199K", 1990000 → "1,99 triệu", 0 → "0"
  /// en: 199000 → "199K", 1990000 → "1.99M", 0 → "0"
  String formatPrice(num price, {required bool en}) {
    if (price == 0) return '0';
    if (en) {
      if (price >= 1000000) {
        final v = (price / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        return '$v M';
      }
      return '${(price / 1000).round()}K';
    } else {
      if (price >= 1000000) {
        final v = (price / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '').replaceAll('.', ',');
        return '$v triệu';
      }
      return '${(price / 1000).round()}K';
    }
  }
}
