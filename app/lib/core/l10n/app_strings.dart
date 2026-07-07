import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { en, bn }

extension AppLocaleCode on AppLocale {
  String get code => name;
  Locale get locale => Locale(code);
}

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.en) {
    _load();
  }

  static const _key = 'gadgetchai_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == 'bn') state = AppLocale.bn;
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(),
);

/// Lightweight bilingual strings (foundation for full l10n).
class S {
  S(this.locale);

  final AppLocale locale;
  bool get isBn => locale == AppLocale.bn;

  static S of(AppLocale locale) => S(locale);

  String get appTitle => isBn ? 'গ্যাজেটচা' : 'GadgetChai';
  String get home => isBn ? 'হোম' : 'Home';
  String get explore => isBn ? 'এক্সপ্লোর' : 'Explore';
  String get cart => isBn ? 'কার্ট' : 'Cart';
  String get account => isBn ? 'অ্যাকাউন্ট' : 'Account';
  String get checkout => isBn ? 'চেকআউট' : 'Checkout';
  String get compare => isBn ? 'তুলনা' : 'Compare';
  String get wishlist => isBn ? 'পছন্দের তালিকা' : 'Wishlist';
  String get business => isBn ? 'ব্যবসায়' : 'Business';
  String get support => isBn ? 'সাপোর্ট' : 'Support';
  String get sustainability => isBn ? 'টেকসই ভাড়া' : 'Sustainable renting';
  String get co2Saved => isBn ? 'আনুমানিক CO₂ সাশ্রয়' : 'Est. CO₂ saved';
  String get devicesActive => isBn ? 'সক্রিয় ডিভাইস' : 'Devices kept active';
  String get studentDiscount => isBn ? 'ছাত্র ছাড় (১০%)' : 'Student discount (10%)';
  String get corporateDiscount => isBn ? 'কর্পোরেট ছাড় (১৫%)' : 'Corporate discount (15%)';
  String get writeReview => isBn ? 'রিভিউ লিখুন' : 'Write a review';
  String get paymentBkash => isBn ? 'বিকাশ' : 'bKash';
  String get paymentNagad => isBn ? 'নগদ (শীঘ্রই)' : 'Nagad (coming soon)';
  String get language => isBn ? 'ভাষা' : 'Language';
  String get english => 'English';
  String get bangla => 'বাংলা';
}

final stringsProvider = Provider<S>((ref) {
  return S(ref.watch(localeProvider));
});
