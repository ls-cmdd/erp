import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  static AppLocalizations? of(BuildContext ctx) =>
      Localizations.of<AppLocalizations>(ctx, AppLocalizations);
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _Delegate();
  bool get isAr => locale.languageCode == 'ar';
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override bool isSupported(Locale l) => ['ar','en'].contains(l.languageCode);
  @override Future<AppLocalizations> load(Locale l) async => AppLocalizations(l);
  @override bool shouldReload(_) => false;
}
