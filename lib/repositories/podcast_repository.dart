import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/podcast.dart';
import '../models/podcast_category.dart';

/// Podcast storage seam. Phase 1 ships [LocalPodcastRepository] (a JSON file on
/// device); a FirestorePodcastRepository implements the same interface later.
abstract interface class PodcastRepository {
  /// Broadcasts the current feed, newest first, filtered by [category] if given.
  Stream<List<Podcast>> watchFeed({PodcastCategory? category});

  Future<List<Podcast>> fetchFeed({PodcastCategory? category});

  /// Persist a podcast that has already passed the language gate.
  Future<void> publish(Podcast podcast);

  Future<void> incrementPlayCount(String id);
}

/// File-backed local implementation. Loads once, keeps an in-memory list, and
/// re-persists on every mutation. Good enough to demo the full
/// record → gate → publish → feed → play loop offline.
class LocalPodcastRepository implements PodcastRepository {
  LocalPodcastRepository();

  final List<Podcast> _podcasts = [];
  final StreamController<List<Podcast>> _controller =
      StreamController<List<Podcast>>.broadcast();
  bool _loaded = false;
  File? _file;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, 'podcasts.json'));
    if (await _file!.exists()) {
      try {
        final raw = jsonDecode(await _file!.readAsString()) as List<dynamic>;
        _podcasts
          ..clear()
          ..addAll(raw.map((e) => Podcast.fromMap(e as Map<String, dynamic>)));
      } catch (_) {
        // Corrupt store — start clean rather than crash.
        _podcasts.clear();
      }
    }
    _loaded = true;
    _emit();
  }

  List<Podcast> _view(PodcastCategory? category) {
    final list = category == null
        ? List<Podcast>.from(_podcasts)
        : _podcasts.where((p) => p.category == category).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _emit() => _controller.add(_view(null));

  Future<void> _persist() async {
    if (_file == null) return;
    await _file!
        .writeAsString(jsonEncode(_podcasts.map((p) => p.toMap()).toList()));
  }

  @override
  Stream<List<Podcast>> watchFeed({PodcastCategory? category}) async* {
    await _ensureLoaded();
    yield _view(category);
    yield* _controller.stream.map((_) => _view(category));
  }

  @override
  Future<List<Podcast>> fetchFeed({PodcastCategory? category}) async {
    await _ensureLoaded();
    return _view(category);
  }

  @override
  Future<void> publish(Podcast podcast) async {
    await _ensureLoaded();
    _podcasts.add(podcast);
    await _persist();
    _emit();
  }

  @override
  Future<void> incrementPlayCount(String id) async {
    await _ensureLoaded();
    final i = _podcasts.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _podcasts[i] = _podcasts[i].copyWith(playCount: _podcasts[i].playCount + 1);
    await _persist();
    _emit();
  }
}
