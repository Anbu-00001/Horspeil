import 'podcast_category.dart';
import 'cefr_level.dart';

/// A published (or draft) German podcast episode.
///
/// Backend-agnostic: [toMap]/[fromMap] use plain JSON-ish types so the same
/// model serializes to the local store today and to Firestore later, behind
/// PodcastRepository. [language] is stored explicitly (always 'de' once past the
/// gate) so the invariant is visible in the data, not just implied by the app.
class Podcast {
  const Podcast({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.category,
    required this.audioUri,
    required this.durationMs,
    required this.createdAt,
    this.description = '',
    this.coverUri,
    this.language = 'de',
    this.cefrLevel,
    this.likeCount = 0,
    this.playCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final PodcastCategory category;

  /// Where the audio lives — a local file path in Phase 1, a Storage URL later.
  final String audioUri;

  /// Optional cover image (local path or URL).
  final String? coverUri;

  final int durationMs;
  final DateTime createdAt;

  /// ISO-639-1 language; invariant 'de' for published episodes.
  final String language;

  /// Optional CEFR tag (Phase 4 filtering).
  final CefrLevel? cefrLevel;

  final int likeCount;
  final int playCount;

  Duration get duration => Duration(milliseconds: durationMs);

  Podcast copyWith({
    String? title,
    String? description,
    PodcastCategory? category,
    String? audioUri,
    String? coverUri,
    int? durationMs,
    CefrLevel? cefrLevel,
    int? likeCount,
    int? playCount,
  }) {
    return Podcast(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId,
      creatorName: creatorName,
      category: category ?? this.category,
      audioUri: audioUri ?? this.audioUri,
      coverUri: coverUri ?? this.coverUri,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt,
      language: language,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      likeCount: likeCount ?? this.likeCount,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'category': category.id,
        'audioUri': audioUri,
        'coverUri': coverUri,
        'durationMs': durationMs,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'language': language,
        'cefrLevel': cefrLevel?.id,
        'likeCount': likeCount,
        'playCount': playCount,
      };

  factory Podcast.fromMap(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? '',
      category: PodcastCategory.fromId(map['category'] as String?) ??
          PodcastCategory.blogs,
      audioUri: map['audioUri'] as String? ?? '',
      coverUri: map['coverUri'] as String?,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      language: map['language'] as String? ?? 'de',
      cefrLevel: CefrLevel.fromId(map['cefrLevel'] as String?),
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }
}
