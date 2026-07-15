import '../config/app_language.dart';

/// All user-facing UI strings, in both languages.
///
/// Deliberately a small hand-rolled table (not full gen-l10n/ARB) — it covers
/// every screen with no codegen step and is trivial to migrate later. Parameter-
/// ised strings are function fields. NOTE: this localises the *interface* only;
/// the language gate stays German-only by design.
class AppStrings {
  AppStrings({
    required this.appName,
    required this.onbTagline1,
    required this.onbTagline2,
    required this.onbSubtitle,
    required this.fieldName,
    required this.fieldEmail,
    required this.fieldPassword,
    required this.signUpCta,
    required this.signInCta,
    required this.toSignIn,
    required this.toSignUp,
    required this.guestCta,
    required this.defaultListenerName,
    required this.authFailed,
    required this.navHome,
    required this.navDiscover,
    required this.navRecord,
    required this.navProfile,
    required this.categoryAll,
    required this.feedEmptyTitle,
    required this.feedEmptyBody,
    required this.noAudioFile,
    required this.playerTitle,
    required this.byCreator,
    required this.profileTitle,
    required this.guestName,
    required this.myPodcasts,
    required this.noRecordings,
    required this.languageLabel,
    required this.recIdleQuote,
    required this.recIdleSub,
    required this.recBtn,
    required this.recTimeLabel,
    required this.recStop,
    required this.recDone,
    required this.recPcmInfo,
    required this.next,
    required this.discard,
    required this.modelPreparing,
    required this.checkingTitle,
    required this.checkingBody,
    required this.modelLoading,
    required this.germanDetected,
    required this.fieldTitle,
    required this.fieldCategory,
    required this.fieldDescription,
    required this.publish,
    required this.noGermanBadge,
    required this.noGermanBody,
    required this.retry,
    required this.requestManual,
    required this.manualRequested,
    required this.checkNotPossibleBadge,
    required this.tryAgainShort,
    required this.checkFailed,
    required this.signInFirst,
    required this.uploadFailed,
    required this.published,
    required this.untitled,
    required this.minutesShort,
  });

  // Brand (kept identical in both languages).
  final String appName;

  // Onboarding
  final String onbTagline1;
  final String onbTagline2;
  final String onbSubtitle;
  final String fieldName;
  final String fieldEmail;
  final String fieldPassword;
  final String signUpCta;
  final String signInCta;
  final String toSignIn;
  final String toSignUp;
  final String guestCta;
  final String defaultListenerName;
  final String Function(String message) authFailed;

  // Bottom nav
  final String navHome;
  final String navDiscover;
  final String navRecord;
  final String navProfile;

  // Feed
  final String categoryAll;
  final String feedEmptyTitle;
  final String feedEmptyBody;
  final String noAudioFile;

  // Player
  final String playerTitle;
  final String Function(String name) byCreator;

  // Profile
  final String profileTitle;
  final String guestName;
  final String myPodcasts;
  final String noRecordings;
  final String languageLabel;

  // Record flow
  final String recIdleQuote;
  final String recIdleSub;
  final String recBtn;
  final String recTimeLabel;
  final String recStop;
  final String Function(String duration) recDone;
  final String Function(int sampleRate) recPcmInfo;
  final String next;
  final String discard;
  final String modelPreparing;
  final String checkingTitle;
  final String checkingBody;
  final String Function(int percent) modelLoading;
  final String germanDetected;
  final String fieldTitle;
  final String fieldCategory;
  final String fieldDescription;
  final String publish;
  final String noGermanBadge;
  final String Function(String detected) noGermanBody;
  final String retry;
  final String requestManual;
  final String manualRequested;
  final String checkNotPossibleBadge;
  final String tryAgainShort;
  final String Function(Object error) checkFailed;
  final String signInFirst;
  final String Function(Object error) uploadFailed;
  final String Function(String title) published;
  final String untitled;

  // Card
  final String Function(int minutes) minutesShort;
}

final AppStrings _de = AppStrings(
  appName: 'Hörspiel',
  onbTagline1: 'Podcasts.',
  onbTagline2: 'Nur auf Deutsch.',
  onbSubtitle: 'Entdecke exklusive Hörspiele und Podcasts in deiner Sprache.',
  fieldName: 'Name',
  fieldEmail: 'E-Mail',
  fieldPassword: 'Passwort',
  signUpCta: 'Kostenlos starten',
  signInCta: 'Anmelden',
  toSignIn: 'Bereits ein Konto? Anmelden',
  toSignUp: 'Noch kein Konto? Jetzt registrieren',
  guestCta: 'Als Gast fortfahren',
  defaultListenerName: 'Hörer',
  authFailed: (m) => 'Anmeldung fehlgeschlagen: $m',
  navHome: 'Startseite',
  navDiscover: 'Entdecken',
  navRecord: 'Aufnehmen',
  navProfile: 'Profil',
  categoryAll: 'Alle',
  feedEmptyTitle: 'Noch keine Hörspiele hier',
  feedEmptyBody: 'Nimm dein erstes deutsches Hörspiel auf — tippe auf „Aufnehmen“.',
  noAudioFile: 'Für dieses Hörspiel gibt es keine Audiodatei.',
  playerTitle: 'WIEDERGABE',
  byCreator: (n) => 'von $n',
  profileTitle: 'Profil',
  guestName: 'Gast',
  myPodcasts: 'Meine Hörspiele',
  noRecordings: 'Noch keine Aufnahmen.',
  languageLabel: 'Sprache',
  recIdleQuote: '„Deine Geschichte beginnt hier…“',
  recIdleSub: 'Nur deutschsprachige Hörspiele werden veröffentlicht.',
  recBtn: 'AUFNAHME',
  recTimeLabel: 'AUFNAHMEZEIT',
  recStop: 'STOPP',
  recDone: (d) => 'Aufnahme fertig ($d)',
  recPcmInfo: (r) => 'PCM • ${r}Hz • Mono',
  next: 'Weiter →',
  discard: 'Verwerfen',
  modelPreparing: 'Modell wird vorbereitet…',
  checkingTitle: 'Sprache wird geprüft…',
  checkingBody: 'Wir hören kurz rein, ob dein Hörspiel auf Deutsch ist. '
      'Das dauert nur einen Augenblick.',
  modelLoading: (p) => 'Modell wird geladen… $p%',
  germanDetected: 'Deutsch erkannt',
  fieldTitle: 'Titel',
  fieldCategory: 'Kategorie',
  fieldDescription: 'Beschreibung',
  publish: 'Veröffentlichen',
  noGermanBadge: 'Kein Deutsch erkannt',
  noGermanBody: (d) => 'Wir konnten kein Deutsch erkennen (erkannt: $d). '
      'Nur deutschsprachige Hörspiele sind erlaubt.',
  retry: 'Erneut versuchen',
  requestManual: 'Manuelle Prüfung anfordern',
  manualRequested: 'Anfrage zur manuellen Prüfung gesendet (Platzhalter).',
  checkNotPossibleBadge: 'Prüfung nicht möglich',
  tryAgainShort: 'Bitte erneut versuchen.',
  checkFailed: (e) => 'Prüfung fehlgeschlagen: $e',
  signInFirst: 'Bitte zuerst anmelden.',
  uploadFailed: (e) => 'Upload fehlgeschlagen: $e',
  published: (t) => 'Veröffentlicht: $t',
  untitled: 'Ohne Titel',
  minutesShort: (m) => '$m Min.',
);

final AppStrings _en = AppStrings(
  appName: 'Hörspiel',
  onbTagline1: 'Podcasts.',
  onbTagline2: 'In German only.',
  onbSubtitle: 'Discover exclusive audio dramas and podcasts in German.',
  fieldName: 'Name',
  fieldEmail: 'Email',
  fieldPassword: 'Password',
  signUpCta: 'Start for free',
  signInCta: 'Sign in',
  toSignIn: 'Already have an account? Sign in',
  toSignUp: "Don't have an account? Register now",
  guestCta: 'Continue as guest',
  defaultListenerName: 'Listener',
  authFailed: (m) => 'Sign-in failed: $m',
  navHome: 'Home',
  navDiscover: 'Discover',
  navRecord: 'Record',
  navProfile: 'Profile',
  categoryAll: 'All',
  feedEmptyTitle: 'No audio dramas here yet',
  feedEmptyBody: 'Record your first German audio drama — tap “Record”.',
  noAudioFile: 'There is no audio file for this drama.',
  playerTitle: 'NOW PLAYING',
  byCreator: (n) => 'by $n',
  profileTitle: 'Profile',
  guestName: 'Guest',
  myPodcasts: 'My audio dramas',
  noRecordings: 'No recordings yet.',
  languageLabel: 'Language',
  recIdleQuote: '“Your story starts here…”',
  recIdleSub: 'Only German-language audio dramas are published.',
  recBtn: 'RECORD',
  recTimeLabel: 'RECORDING TIME',
  recStop: 'STOP',
  recDone: (d) => 'Recording done ($d)',
  recPcmInfo: (r) => 'PCM • ${r}Hz • Mono',
  next: 'Next →',
  discard: 'Discard',
  modelPreparing: 'Preparing model…',
  checkingTitle: 'Checking language…',
  checkingBody: 'We listen in briefly to check whether your drama is in German. '
      'It only takes a moment.',
  modelLoading: (p) => 'Loading model… $p%',
  germanDetected: 'German detected',
  fieldTitle: 'Title',
  fieldCategory: 'Category',
  fieldDescription: 'Description',
  publish: 'Publish',
  noGermanBadge: 'No German detected',
  noGermanBody: (d) => 'We could not detect German (detected: $d). '
      'Only German-language audio dramas are allowed.',
  retry: 'Try again',
  requestManual: 'Request manual review',
  manualRequested: 'Manual review requested (placeholder).',
  checkNotPossibleBadge: 'Check not possible',
  tryAgainShort: 'Please try again.',
  checkFailed: (e) => 'Check failed: $e',
  signInFirst: 'Please sign in first.',
  uploadFailed: (e) => 'Upload failed: $e',
  published: (t) => 'Published: $t',
  untitled: 'Untitled',
  minutesShort: (m) => '$m min',
);

/// Returns the string table for [lang].
AppStrings stringsFor(AppLanguage lang) =>
    lang == AppLanguage.en ? _en : _de;
