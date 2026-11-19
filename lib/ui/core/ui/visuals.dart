import 'package:flutter/material.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/challenge.dart';
import '../../../domain/models/ritual.dart';
import '../themes/colors.dart';

/// Par de cores (fundo/ícone) usado em badges.
typedef Tint = ({Color background, Color foreground});

/// Mapeamentos de domínio → ícones/cores (mantém o domínio livre de Flutter).
abstract final class Visuals {
  static IconData stepIcon(StepType type) => switch (type) {
    StepType.hydration => Icons.water_drop_outlined,
    StepType.movement => Icons.self_improvement,
    StepType.breathing => Icons.air,
    StepType.meditation => Icons.spa_outlined,
    StepType.reading => Icons.menu_book_outlined,
    StepType.journaling => Icons.edit_note,
    StepType.custom => Icons.auto_awesome_outlined,
  };

  static Tint stepTint(StepType type) => switch (type) {
    StepType.hydration => (
      background: AppColors.tertiaryFixed,
      foreground: AppColors.tertiaryContainer,
    ),
    StepType.movement => (
      background: AppColors.secondaryFixed,
      foreground: AppColors.secondary,
    ),
    StepType.breathing || StepType.meditation => (
      background: AppColors.primaryFixed,
      foreground: AppColors.primaryContainer,
    ),
    StepType.reading || StepType.journaling => (
      background: const Color(0xFFFFE6C7),
      foreground: AppColors.secondary,
    ),
    StepType.custom => (
      background: AppColors.surfaceHighest,
      foreground: AppColors.primaryContainer,
    ),
  };

  static IconData periodIcon(RitualPeriod p) => switch (p) {
    RitualPeriod.morning => Icons.wb_sunny_outlined,
    RitualPeriod.afternoon => Icons.wb_twilight,
    RitualPeriod.night => Icons.bedtime_outlined,
  };

  static IconData categoryIcon(ChallengeCategory c) => switch (c) {
    ChallengeCategory.nutrition => Icons.no_food_outlined,
    ChallengeCategory.reading => Icons.menu_book_outlined,
    ChallengeCategory.hydration => Icons.water_drop_outlined,
    ChallengeCategory.sleep => Icons.nights_stay_outlined,
    ChallengeCategory.movement => Icons.directions_run,
    ChallengeCategory.mindfulness => Icons.spa_outlined,
    ChallengeCategory.morning => Icons.wb_sunny_outlined,
  };

  static Tint categoryTint(ChallengeCategory c) => switch (c) {
    ChallengeCategory.hydration => (
      background: AppColors.tertiaryFixed,
      foreground: AppColors.tertiaryContainer,
    ),
    ChallengeCategory.sleep => (
      background: AppColors.restContainer,
      foreground: AppColors.rest,
    ),
    ChallengeCategory.reading || ChallengeCategory.movement => (
      background: AppColors.secondaryFixed,
      foreground: AppColors.secondary,
    ),
    _ => (
      background: AppColors.primaryFixed,
      foreground: AppColors.primaryContainer,
    ),
  };

  static IconData achievementIcon(AchievementIcon i) => switch (i) {
    AchievementIcon.sunrise => Icons.wb_twilight,
    AchievementIcon.water => Icons.opacity,
    AchievementIcon.group => Icons.groups_outlined,
    AchievementIcon.focus => Icons.psychology_alt_outlined,
    AchievementIcon.seedling => Icons.eco_outlined,
    AchievementIcon.book => Icons.menu_book_outlined,
    AchievementIcon.moon => Icons.bedtime_outlined,
    AchievementIcon.flame => Icons.local_fire_department_outlined,
  };

  static Tint achievementTint(AchievementIcon i) => switch (i) {
    AchievementIcon.water => (
      background: AppColors.tertiaryFixed,
      foreground: AppColors.tertiaryContainer,
    ),
    AchievementIcon.moon => (
      background: AppColors.restContainer,
      foreground: AppColors.rest,
    ),
    AchievementIcon.sunrise || AchievementIcon.flame => (
      background: AppColors.secondaryFixed,
      foreground: AppColors.secondary,
    ),
    _ => (
      background: AppColors.primaryFixed,
      foreground: AppColors.primaryContainer,
    ),
  };
}
