import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_palette.dart';
import '../../models/podcast.dart';
import '../../models/podcast_category.dart';
import '../../services/audio/pcm_codec.dart';
import '../../services/audio/recorder_service.dart';
import '../../services/language_gate/language_gate.dart';
import '../../services/language_gate/language_gate_result.dart';
import '../../services/language_gate/model_provisioner.dart';

enum _Stage { idle, recording, review, checking, accepted, rejected, uncertain }

/// The signature flow: record → language gate → publish. Only clips the
/// on-device gate accepts as German can be published.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final RecorderService _recorder = RecorderService();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  _Stage _stage = _Stage.idle;
  RecordingResult? _recording;
  LanguageGateResult? _gateResult;
  LanguageGate? _gate;
  PodcastCategory _category = PodcastCategory.blogs;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  double _modelProgress = 0;
  String _status = '';
  StreamSubscription<double>? _levelSub;

  @override
  void dispose() {
    _timer?.cancel();
    _levelSub?.cancel();
    _recorder.dispose();
    _gate?.dispose();
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _recorder.start();
    } catch (e) {
      _snack('$e');
      return;
    }
    _elapsed = Duration.zero;
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _elapsed += const Duration(seconds: 1)));
    _levelSub = _recorder.levels.listen((l) => setState(() => _level = l));
    setState(() => _stage = _Stage.recording);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _levelSub?.cancel();
    final result = await _recorder.stop();
    setState(() {
      _recording = result;
      _stage = _Stage.review;
    });
  }

  Future<void> _runGate() async {
    setState(() {
      _stage = _Stage.checking;
      _status = 'Modell wird vorbereitet…';
      _modelProgress = 0;
    });
    try {
      final config = context.read<AppServices>().config;
      final model = await ModelProvisioner(source: config.modelSource)
          .ensure(onProgress: (p) => setState(() => _modelProgress = p));
      _gate = SherpaLanguageGate(model: model, config: config.languageGate);

      setState(() => _status = 'Sprache wird geprüft…');
      final bytes = await File(_recording!.pcmPath).readAsBytes();
      final samples = PcmCodec.pcm16ToFloat32(bytes);
      final result =
          await _gate!.analyzeSamples(samples, _recording!.sampleRate);

      setState(() {
        _gateResult = result;
        _stage = switch (result.decision) {
          GateDecision.accepted => _Stage.accepted,
          GateDecision.rejected => _Stage.rejected,
          GateDecision.uncertain => _Stage.uncertain,
        };
      });
    } catch (e) {
      setState(() {
        _status = 'Prüfung fehlgeschlagen: $e';
        _stage = _Stage.uncertain;
      });
    }
  }

  Future<void> _publish() async {
    final services = context.read<AppServices>();
    final user = services.auth.currentUser;
    if (user == null || _recording == null) return;
    final podcast = Podcast(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim().isEmpty ? 'Ohne Titel' : _title.text.trim(),
      description: _desc.text.trim(),
      creatorId: user.id,
      creatorName: user.displayName,
      category: _category,
      audioUri: _recording!.wavPath,
      durationMs: _recording!.duration.inMilliseconds,
      createdAt: DateTime.now(),
    );
    await services.podcasts.publish(podcast);
    if (!mounted) return;
    _snack('Veröffentlicht: ${podcast.title}');
    _reset();
  }

  void _reset() {
    _title.clear();
    _desc.clear();
    setState(() {
      _stage = _Stage.idle;
      _recording = null;
      _gateResult = null;
      _elapsed = Duration.zero;
      _level = 0;
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufnehmen'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (_stage) {
          _Stage.idle => _idleView(),
          _Stage.recording => _recordingView(),
          _Stage.review => _reviewView(),
          _Stage.checking => _checkingView(),
          _Stage.accepted => _acceptedView(),
          _Stage.rejected => _rejectedView(),
          _Stage.uncertain => _uncertainView(),
        },
      ),
    );
  }

  Widget _idleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('„Deine Geschichte beginnt hier…“',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Nur deutschsprachige Hörspiele werden veröffentlicht.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 40),
          _bigMicButton(onTap: _start, label: 'AUFNAHME'),
        ],
      ),
    );
  }

  Widget _recordingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('AUFNAHMEZEIT',
              style: TextStyle(letterSpacing: 2, color: AppPalette.mutedText)),
          const SizedBox(height: 8),
          Text(_fmt(_elapsed),
              style: const TextStyle(
                  fontSize: 56, fontWeight: FontWeight.w300, fontFeatures: [])),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: _level.clamp(0.0, 1.0),
            color: AppPalette.primary,
            backgroundColor: AppPalette.border,
          ),
          const SizedBox(height: 40),
          _bigMicButton(
              onTap: _stop, label: 'STOPP', icon: Icons.stop, pulse: true),
        ],
      ),
    );
  }

  Widget _reviewView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 64, color: AppPalette.secondary),
          const SizedBox(height: 16),
          Text('Aufnahme fertig (${_fmt(_recording?.duration ?? Duration.zero)})',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('PCM • ${_recording?.sampleRate}Hz • Mono',
              style: TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 32),
          FilledButton(
              onPressed: _runGate, child: const Text('Weiter →')),
          TextButton(onPressed: _reset, child: const Text('Verwerfen')),
        ],
      ),
    );
  }

  Widget _checkingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.graphic_eq, size: 56, color: AppPalette.primary),
          const SizedBox(height: 24),
          Text('Sprache wird geprüft…',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              'Wir hören kurz rein, ob dein Hörspiel auf Deutsch ist. '
              'Das dauert nur einen Augenblick.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 24),
          if (_modelProgress > 0 && _modelProgress < 1)
            Column(children: [
              Text('Modell wird geladen… ${(_modelProgress * 100).round()}%',
                  style: TextStyle(color: AppPalette.mutedText)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: _modelProgress, color: AppPalette.primary),
            ])
          else
            const CircularProgressIndicator(color: AppPalette.primary),
        ],
      ),
    );
  }

  Widget _acceptedView() {
    return ListView(
      children: [
        _badge('Deutsch erkannt', AppPalette.success, Icons.verified),
        const SizedBox(height: 20),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
              labelText: 'Titel', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PodcastCategory>(
          initialValue: _category,
          decoration: const InputDecoration(
              labelText: 'Kategorie', border: OutlineInputBorder()),
          items: [
            for (final c in PodcastCategory.values)
              DropdownMenuItem(value: c, child: Text(c.germanLabel)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Beschreibung', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: _publish, child: const Text('Veröffentlichen')),
        TextButton(onPressed: _reset, child: const Text('Verwerfen')),
      ],
    );
  }

  Widget _rejectedView() {
    final detected = _gateResult?.detectedLang ?? '—';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _badge('Kein Deutsch erkannt', AppPalette.error, Icons.info_outline),
          const SizedBox(height: 16),
          Text(
              'Wir konnten kein Deutsch erkennen (erkannt: $detected). '
              'Nur deutschsprachige Hörspiele sind erlaubt.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _runGate, child: const Text('Erneut versuchen')),
          TextButton(
            onPressed: () =>
                _snack('Anfrage zur manuellen Prüfung gesendet (Platzhalter).'),
            child: const Text('Manuelle Prüfung anfordern'),
          ),
          TextButton(onPressed: _reset, child: const Text('Verwerfen')),
        ],
      ),
    );
  }

  Widget _uncertainView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _badge('Prüfung nicht möglich', AppPalette.mutedText, Icons.help_outline),
          const SizedBox(height: 16),
          Text(_status.isEmpty ? 'Bitte erneut versuchen.' : _status,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _runGate, child: const Text('Erneut versuchen')),
          TextButton(onPressed: _reset, child: const Text('Verwerfen')),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _bigMicButton({
    required VoidCallback onTap,
    required String label,
    IconData icon = Icons.mic,
    bool pulse = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppPalette.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppPalette.primary.withValues(alpha: pulse ? 0.5 : 0.3),
                blurRadius: pulse ? 32 : 16,
                spreadRadius: pulse ? 4 : 0),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
