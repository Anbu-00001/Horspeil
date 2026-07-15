import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_palette.dart';
import '../../config/locale_controller.dart';
import '../../models/podcast.dart';
import '../../services/audio/player_service.dart';

/// Now-playing screen (Wiedergabe): cover, title, creator, scrubber, transport.
/// Like/comment are shown but disabled — those are Phase 2.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.podcast});

  final Podcast podcast;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final PlayerService _player;

  @override
  void initState() {
    super.initState();
    _player = context.read<AppServices>().player;
    _player.playSource(widget.podcast.audioUri);
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.podcast;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.of(context).pop()),
        title: Text(context.l10n.playerTitle,
            style: const TextStyle(
                fontSize: 13, letterSpacing: 2, color: AppPalette.mutedText)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.graphic_eq,
                    size: 96, color: AppPalette.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(p.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(context.l10n.byCreator(p.creatorName),
                style: TextStyle(
                    color: AppPalette.mutedText,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            _scrubber(),
            const SizedBox(height: 12),
            _transport(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _scrubber() {
    return StreamBuilder<Duration>(
      stream: _player.position,
      builder: (context, posSnap) {
        return StreamBuilder<Duration?>(
          stream: _player.duration,
          builder: (context, durSnap) {
            final total = durSnap.data ?? Duration.zero;
            final pos = posSnap.data ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final value =
                maxMs == 0 ? 0.0 : pos.inMilliseconds.clamp(0, maxMs).toDouble();
            return Column(
              children: [
                Slider(
                  min: 0,
                  max: maxMs == 0 ? 1 : maxMs,
                  value: value,
                  activeColor: AppPalette.primary,
                  onChanged: maxMs == 0
                      ? null
                      : (v) =>
                          _player.seek(Duration(milliseconds: v.round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos),
                        style: TextStyle(color: AppPalette.mutedText)),
                    Text(_fmt(total),
                        style: TextStyle(color: AppPalette.mutedText)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _transport() {
    return StreamBuilder<PlayerState>(
      stream: _player.playerState,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              color: AppPalette.mutedText,
              icon: const Icon(Icons.favorite_border),
              onPressed: null, // Phase 2
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.replay_10),
              onPressed: () => _player.seek(Duration.zero),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.large(
              backgroundColor: AppPalette.primary,
              onPressed: () => playing ? _player.pause() : _player.resume(),
              child: Icon(playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.forward_10),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 32,
              color: AppPalette.mutedText,
              icon: const Icon(Icons.mode_comment_outlined),
              onPressed: null, // Phase 2
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
