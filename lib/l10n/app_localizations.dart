import 'package:flutter/material.dart';
import 'translations_en.dart';
import 'translations_pa.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('pa')];

  Map<String, String> get _localizedStrings {
    switch (locale.languageCode) {
      case 'pa':
        return translationsPa;
      default:
        return translationsEn;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? translationsEn[key] ?? key;
  }

  String translateWithArgs(String key, Map<String, String> args) {
    String text = translate(key);
    args.forEach((argKey, value) {
      text = text.replaceAll('{$argKey}', value);
    });
    return text;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pa'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
