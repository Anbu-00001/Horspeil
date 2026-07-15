import '../config/app_language.dart';

/// Podcast categories for Hörspiel.
///
/// NOTE (taxonomy decision, 2026-07-13): the written spec asked for *topic*
/// categories (Food, Travel, Culture, Blogs, Education). The Stitch design
/// mockups instead lean into *audio-drama genres* (Krimi, Historisch, Lyrik,
/// Kinder …). This enum encodes the spec's topics; it is intentionally the
/// single place the taxonomy lives, so switching to a genre taxonomy — or
/// merging both — is a localized change. Persisted values use [id], so renaming
/// a label never breaks stored data.
enum PodcastCategory {
  food('food', 'Essen', 'Food'),
  travel('travel', 'Reisen', 'Travel'),
  culture('culture', 'Kultur', 'Culture'),
  blogs('blogs', 'Blogs', 'Blogs'),
  education('education', 'Bildung', 'Education'),
  history('history', 'Geschichte', 'History'),
  science('science', 'Wissenschaft', 'Science'),
  music('music', 'Musik', 'Music');

  const PodcastCategory(this.id, this.germanLabel, this.englishLabel);

  /// Stable identifier persisted in the datastore. Never change these strings.
  final String id;

  /// Label shown in the German UI.
  final String germanLabel;

  /// English label (useful for CEFR learners / accessibility).
  final String englishLabel;

  /// Label for the active UI language.
  String label(AppLanguage lang) =>
      lang == AppLanguage.en ? englishLabel : germanLabel;

  static PodcastCategory? fromId(String? id) {
    if (id == null) return null;
    for (final c in PodcastCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
