import 'package:flutter/material.dart';

import '../../../domain/models/challenge.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';
import '../view_models/home_viewmodel.dart';

/// Carrossel horizontal "Desafios em Tribo".
class ChallengeCarousel extends StatelessWidget {
  const ChallengeCarousel({
    super.key,
    required this.challenges,
    required this.onTap,
    required this.onCreate,
  });

  final List<ChallengeSummary> challenges;
  final void Function(Challenge) onTap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: Dimens.screenPadding,
        clipBehavior: Clip.none,
        itemCount: challenges.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: Dimens.gutter),
        itemBuilder: (context, i) {
          if (i == challenges.length) {
            return SizedBox(
              width: 150,
              child: SereneCard(
                color: AppColors.surfaceContainer,
                shadow: false,
                onTap: onCreate,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const IconBadge(icon: Icons.add, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      'Criar desafio com amigos',
                      textAlign: TextAlign.center,
                      style: t.labelLarge,
                    ),
                  ],
                ),
              ),
            );
          }
          final s = challenges[i];
          final c = s.challenge;
          final tint = Visuals.categoryTint(c.category);
          return SizedBox(
            width: 264,
            child: SereneCard(
              padding: EdgeInsets.zero,
              onTap: () => onTap(c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PillBadge(
                              label: 'Dia ${s.day} de ${c.durationDays}',
                              dense: true,
                              background: tint.background,
                              foreground: tint.foreground,
                            ),
                            const Spacer(),
                            Icon(
                              Visuals.categoryIcon(c.category),
                              color: tint.foreground,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium,
                        ),
                        Text(
                          c.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(Dimens.radiusMd),
                      ),
                    ),
                    child: Row(
                      children: [
                        AvatarStack(
                          users: s.recentAuthors.isEmpty
                              ? c.members
                              : s.recentAuthors,
                          size: 28,
                        ),
                        const Spacer(),
                        Text(
                          s.checkInsToday == 1
                              ? '1 check-in hoje'
                              : '${s.checkInsToday} check-ins hoje',
                          style: t.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
