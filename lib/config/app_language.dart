/// UI language for the app chrome. This is ONLY about which language the
/// interface text is shown in — it has nothing to do with the language gate,
/// which always detects spoken German regardless of this setting.
enum AppLanguage {
  de('de', 'Deutsch'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  /// ISO-639-1 code, persisted.
  final String code;

  /// Name shown for this option in the language toggle.
  final String nativeName;

  static AppLanguage fromCode(String? code) {
    for (final l in AppLanguage.values) {
      if (l.code == code) return l;
    }
    return AppLanguage.de;
  }
}
