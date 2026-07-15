import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import 'app_language.dart';

/// Holds the current UI language and exposes the matching [AppStrings]. Persists
/// the choice so it survives restarts. Purely about interface text — the
/// language gate is unaffected.
class LocaleController extends ChangeNotifier {
  LocaleController(this._lang, [this._prefs]);

  AppLanguage _lang;
  final SharedPreferences? _prefs;

  static const String _prefsKey = 'app_language';

  AppLanguage get language => _lang;
  AppStrings get strings => stringsFor(_lang);

  /// Loads the saved language (defaults to German). Tolerates a missing/failed
  /// prefs backend (e.g. in tests) by falling back to an in-memory controller.
  static Future<LocaleController> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return LocaleController(AppLanguage.fromCode(prefs?.getString(_prefsKey)), prefs);
  }

  void setLanguage(AppLanguage lang) {
    if (lang == _lang) return;
    _lang = lang;
    _prefs?.setString(_prefsKey, lang.code);
    notifyListeners();
  }

  void toggle() =>
      setLanguage(_lang == AppLanguage.de ? AppLanguage.en : AppLanguage.de);
}

/// Ergonomic access from widgets.
extension LocalizationX on BuildContext {
  /// Localised strings that REBUILD the caller on language change. Use in build().
  AppStrings get l10n => watch<LocaleController>().strings;

  /// Localised strings WITHOUT subscribing. Use in callbacks / async methods.
  AppStrings get strings => read<LocaleController>().strings;

  /// Active UI language (rebuilds the caller on change). Use in build().
  AppLanguage get localeLanguage => watch<LocaleController>().language;
}
