import 'package:flutter/material.dart';

import '../../config/app_palette.dart';
import '../../models/podcast.dart';

/// Feed/list card, styled after the "Neuerscheinungen" cards in the mockups:
/// cover thumbnail, serif title, creator • category, duration, play button.
class PodcastCard extends StatelessWidget {
  const PodcastCard({super.key, required this.podcast, required this.onPlay});

  final Podcast podcast;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final minutes = podcast.duration.inMinutes;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _cover(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'serif', fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${podcast.creatorName} • ${podcast.category.germanLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppPalette.mutedText, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tag(podcast.category.germanLabel.toUpperCase()),
                      const SizedBox(width: 8),
                      if (minutes > 0)
                        Text('$minutes Min.',
                            style: TextStyle(
                                color: AppPalette.mutedText, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              color: AppPalette.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.graphic_eq, color: AppPalette.primary),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppPalette.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: AppPalette.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}
