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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.05 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
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
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: isFavorite ? Colors.red : (isLight ? Colors.black12 : Colors.white24),
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
                Text(court.distName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: isLight ? Colors.black54 : null)),
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    Color chipColor;
    Color textColor;
    Color borderColor;

    if (!isAvailable) {
      chipColor = isLight ? Colors.black.withOpacity(0.02) : Colors.white.withOpacity(0.02);
      textColor = isLight ? Colors.black12 : Colors.white24;
      borderColor = isLight ? Colors.black.withOpacity(0.05) : Colors.white10;
    } else {
      final count = session.sessionCount;
      Color baseColor;
      
      if (count <= 1) {
        baseColor = isLight ? Colors.red.shade700 : Colors.redAccent;
      } else if (count <= 2) {
        baseColor = isLight ? Colors.orange.shade700 : Colors.orangeAccent;
      } else if (count <= 3) {
        baseColor = isLight ? Colors.amber.shade700 : Colors.amberAccent;
      } else {
        baseColor = isLight ? Colors.green.shade700 : Colors.greenAccent;
      }

      chipColor = baseColor.withOpacity(isLight ? 0.05 : 0.15);
      textColor = baseColor;
      borderColor = baseColor.withOpacity(isLight ? 0.2 : 0.4);
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
                  color: isAvailable ? textColor.withOpacity(0.7) : textColor,
                  fontSize: 10,
                  fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
