import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/court_session.dart';
import '../providers/court_provider.dart';
import '../theme/app_theme.dart';

class CourtCard extends ConsumerWidget {
  final GroupedCourt court;

  const CourtCard({super.key, required this.court});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(court.venueId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        court.venueName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        court.fatName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (court.hasPeakHour)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 Peak',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFavorite ? Colors.amber : Colors.white24,
                  ),
                  onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(court.venueId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 14),
                const SizedBox(width: 4),
                Text(court.distName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: court.sessions.map((session) => _buildTimeChip(context, session)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, CourtSession session) {
    final startTime = session.ssnStartTime.substring(0, 5);
    final isAvailable = session.available;
    final isPeak = session.peakHour;

    Color chipColor;
    Color textColor;
    Color borderColor;

    if (!isAvailable) {
      chipColor = Colors.white.withOpacity(0.02);
      textColor = Colors.white24;
      borderColor = Colors.white10;
    } else {
      chipColor = Colors.green.withOpacity(0.15);
      textColor = Colors.greenAccent;
      borderColor = Colors.green.withOpacity(0.4);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                startTime,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${session.sessionCount})',
                style: TextStyle(
                  color: isAvailable ? textColor.withOpacity(0.5) : Colors.white10,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (isPeak)
          const Positioned(
            top: -8,
            right: -6,
            child: Text(
              '🔥',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
