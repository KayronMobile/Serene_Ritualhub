import 'package:flutter/material.dart';

import '../../../domain/models/challenge.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';

/// "Placar da Turma": taxa do grupo + ranking de consistência.
class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({
    super.key,
    required this.entries,
    required this.groupRate,
    required this.myId,
    required this.isFinished,
  });

  final List<LeaderboardEntry> entries;
  final double groupRate;
  final String? myId;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final activeToday = entries.where((e) => e.checkedInToday).length;
    final pct = (groupRate * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Rhythm & Accountability',
          title: 'Placar da Turma',
          trailing: PillBadge(
            label: isFinished ? 'Encerrado' : '$activeToday ativos hoje',
            icon: Icons.bolt,
            background: AppColors.secondaryFixed,
            foreground: AppColors.secondary,
            dense: true,
          ),
        ),
        const SizedBox(height: Dimens.spaceMd),
        SereneCard(
          color: AppColors.surfaceContainer,
          shadow: false,
          padding: const EdgeInsets.all(Dimens.spaceMd),
          child: Row(
            children: [
              const IconBadge(
                icon: Icons.groups_outlined,
                background: AppColors.primaryFixed,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$pct% de taxa de sucesso', style: t.titleSmall),
                    Text(
                      pct >= 90
                          ? 'Tribo em sintonia! Continuem assim. 🌿'
                          : 'Quase lá! Um check-in de cada vez eleva o grupo.',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.spaceMd),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimens.spaceSm),
            child: _Row(
              position: i + 1,
              entry: entries[i],
              isMe: entries[i].member.id == myId,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.position, required this.entry, required this.isMe});

  final int position;
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final medal = switch (position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => null,
    };
    return SereneCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: Dimens.radiusLg,
      color: isMe ? AppColors.surfaceLow : AppColors.surfaceLowest,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal != null
                ? Icon(Icons.emoji_events, color: medal, size: 22)
                : Text('$position°', style: t.titleSmall),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(user: entry.member, size: 42),
              if (entry.checkedInToday)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.member.name,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const Flexible(
                        child: PillBadge(label: 'Você', dense: true),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 14,
                      color: AppColors.terracotta,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${entry.currentStreak} dias seguidos',
                        style: t.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.elapsedDays == 0
                      ? '—'
                      : '${(entry.consistency * 100).round()}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  entry.mood,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
