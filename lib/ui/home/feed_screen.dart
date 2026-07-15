import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_palette.dart';
import '../../config/locale_controller.dart';
import '../../models/podcast.dart';
import '../../models/podcast_category.dart';
import '../player/player_screen.dart';
import '../widgets/podcast_card.dart';

/// Home / discovery feed: category chips + a live list from the repository.
/// Empty state mirrors the mockup ("Noch keine Hörspiele hier").
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  PodcastCategory? _category;

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appName)),
      body: Column(
        children: [
          _categoryChips(),
          Expanded(
            child: StreamBuilder<List<Podcast>>(
              stream: services.podcasts.watchFeed(category: _category),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) return _empty();
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => PodcastCard(
                    podcast: items[i],
                    onPlay: () => _play(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    final services = context.read<AppServices>();
    final categories = services.config.categories;
    final lang = context.watch<LocaleController>().language;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(context.l10n.categoryAll),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                label: Text(c.label(lang)),
                selected: _category == c,
                selectedColor: AppPalette.primary,
                labelStyle: TextStyle(
                    color: _category == c ? Colors.white : AppPalette.ink),
                onSelected: (_) => setState(() => _category = c),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 64, color: AppPalette.mutedText),
            const SizedBox(height: 16),
            Text(context.l10n.feedEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              context.l10n.feedEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  void _play(Podcast podcast) {
    if (podcast.audioUri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.noAudioFile)),
      );
      return;
    }
    context.read<AppServices>().podcasts.incrementPlayCount(podcast.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerScreen(podcast: podcast)),
    );
  }
}
