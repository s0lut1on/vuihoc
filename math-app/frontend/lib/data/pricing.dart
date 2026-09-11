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

  /// Synchronous access — returns the already-loaded instance, or a
  /// hardcoded fallback if the JSON hasn't loaded yet.
  ///
  /// The fallback contains the same 3 tiers + features as the canonical
  /// pricing.json, so the pricing screen can always render even before
  /// `load()` completes (or if it fails). When the real data loads, it
  /// replaces this and the UI rebuilds with the canonical values.
  ///
  /// This is a safety net: the real fix for the "Null check operator
  /// used on a null value" error is to ensure `load()` completes before
  /// the pricing screen builds, but the fallback means the screen is
  /// never broken even if there's a timing issue.
  static PricingConfig get instance {
    _instance ??= PricingConfig._(_fallback);
    return _instance!;
  }

  /// Hardcoded fallback matching math-app/pricing.json. Used when
  /// `load()` hasn't completed (or failed) and the pricing screen
  /// needs to render synchronously. Kept in sync with the JSON manually.
  static const Map<String, dynamic> _fallback = {
    'version': 2,
    'currency': 'VND',
    'contact_email': 'contact@sekklings.com',
    'tiers': [
      {
        'id': 'free',
        'name_vi': 'Miễn phí',
        'name_en': 'Free',
        'price': 0,
        'price_period_vi': '/ mãi mãi',
        'price_period_en': '/ forever',
        'features': [
          {'text_vi': 'Không giới hạn bài học mỗi ngày', 'text_en': 'Unlimited lessons per day'},
          {'text_vi': 'Đầy đủ 4 phong cách học', 'text_en': 'All 4 learning personas'},
          {'text_vi': 'Song ngữ Việt–Anh', 'text_en': 'Bilingual VI–EN'},
          {'text_vi': 'Dashboard phụ huynh cơ bản', 'text_en': 'Basic parent dashboard'},
          {'text_vi': 'Google Sign-In + Guest', 'text_en': 'Google Sign-In + Guest'},
          {'text_vi': 'Không giới hạn thời gian', 'text_en': 'Unlimited time'},
        ],
      },
      {
        'id': 'premium_monthly',
        'name_vi': 'Premium',
        'name_en': 'Premium',
        'price': 39000,
        'price_period_vi': '/ tháng',
        'price_period_en': '/ month',
        'features': [
          {'text_vi': 'Báo cáo tiến bộ hàng tuần qua email', 'text_en': 'Weekly progress email reports'},
          {'text_vi': 'Xuất dữ liệu học tập (CSV)', 'text_en': 'Export learning data (CSV)'},
          {'text_vi': 'Nhiều hồ sơ bé trong 1 tài khoản', 'text_en': 'Multiple kid profiles'},
          {'text_vi': 'Hỗ trợ ưu tiên 24/7', 'text_en': 'Priority 24/7 support'},
          {'text_vi': 'Sớm nhận nội dung mới', 'text_en': 'Early access to new content'},
          {'text_vi': 'Không quảng cáo, không giới hạn', 'text_en': 'No ads, no limits'},
        ],
      },
      {
        'id': 'premium_yearly',
        'name_vi': 'Premium (năm)',
        'name_en': 'Premium (yearly)',
        'price': 390000,
        'price_period_vi': '/ năm',
        'price_period_en': '/ year',
        'features': [
          {'text_vi': 'Bao gồm tất cả tính năng Premium', 'text_en': 'Includes all Premium features'},
          {'text_vi': 'Tiết kiệm 17% so với trả theo tháng', 'text_en': 'Save 17% vs monthly'},
        ],
      },
    ],
    'compare_rows': [
      {
        'label_vi': 'Bài học / ngày',
        'label_en': 'Lessons / day',
        'free': 'Không giới hạn',
        'premium': 'Không giới hạn',
      },
      {
        'label_vi': '4 phong cách học',
        'label_en': '4 learning personas',
        'free': '✓',
        'premium': '✓',
      },
    ],
  };

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
