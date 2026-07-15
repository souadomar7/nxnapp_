import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nxnapp/providers/locale_provider.dart';

void main() {
  group('LocaleProvider Tests', () {
    test('Initial locale should be English (en)', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, 'en');
    });

    test('toggleLocale should switch between English and Arabic', () {
      final provider = LocaleProvider();
      
      provider.toggleLocale();
      expect(provider.locale.languageCode, 'ar');

      provider.toggleLocale();
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale should change to a valid locale', () {
      final provider = LocaleProvider();
      
      provider.setLocale(const Locale('ar'));
      expect(provider.locale.languageCode, 'ar');

      // Invalid locale change should be ignored
      provider.setLocale(const Locale('fr'));
      expect(provider.locale.languageCode, 'ar');
    });
  });
}
