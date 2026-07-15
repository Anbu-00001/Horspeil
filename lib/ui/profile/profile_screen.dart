import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_language.dart';
import '../../config/app_palette.dart';
import '../../config/locale_controller.dart';
import '../../models/podcast.dart';
import '../widgets/podcast_card.dart';

/// Minimal profile: the signed-in user's identity + their uploaded podcasts,
/// plus the UI-language toggle.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final user = services.auth.currentUser;
    final s = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppPalette.mutedText),
            onPressed: () => services.auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppPalette.primary.withValues(alpha: 0.15),
              child: Text(
                (user?.displayName.isNotEmpty ?? false)
                    ? user!.displayName.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 32,
                    color: AppPalette.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(user?.displayName ?? s.guestName,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          if (user?.email != null)
            Center(
                child: Text(user!.email!,
                    style: TextStyle(color: AppPalette.mutedText))),
          const SizedBox(height: 20),
          const _LanguageRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(s.myPodcasts,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          StreamBuilder<List<Podcast>>(
            stream: services.podcasts.watchFeed(),
            builder: (context, snapshot) {
              final mine = (snapshot.data ?? [])
                  .where((p) => p.creatorId == user?.id)
                  .toList();
              if (mine.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.noRecordings,
                      style: TextStyle(color: AppPalette.mutedText)),
                );
              }
              return Column(
                children: [
                  for (final p in mine)
                    PodcastCard(podcast: p, onPlay: () {}),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// UI-language selector shown on the profile screen.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    return ListTile(
      leading: const Icon(Icons.language, color: AppPalette.primary),
      title: Text(context.l10n.languageLabel),
      trailing: SegmentedButton<AppLanguage>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: AppLanguage.de, label: Text('DE')),
          ButtonSegment(value: AppLanguage.en, label: Text('EN')),
        ],
        selected: {controller.language},
        onSelectionChanged: (sel) => controller.setLanguage(sel.first),
      ),
    );
  }
}
