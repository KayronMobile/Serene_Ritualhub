import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/models/user_profile.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'visuals.dart';

/// Card de superfície branca com sombra ambiente.
class SereneCard extends StatelessWidget {
  const SereneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Dimens.spaceLg),
    this.color = AppColors.surfaceLowest,
    this.radius = Dimens.radiusMd,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? Dimens.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? content
            : InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: content,
              ),
      ),
    );
  }
}

/// Selo em formato de pílula.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.primary,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Pílula de sequência (chama/ritmo).
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) => PillBadge(
    label: '${days}d',
    icon: Icons.local_fire_department_outlined,
    background: AppColors.amber.withValues(alpha: 0.18),
    foreground: AppColors.terracotta,
  );
}

/// Ícone dentro de um "seixo" colorido.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.primaryContainer,
    this.size = 40,
  });

  factory IconBadge.tint(IconData icon, Tint tint, {double size = 40}) =>
      IconBadge(
        icon: icon,
        background: tint.background,
        foreground: tint.foreground,
        size: size,
      );

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, color: foreground, size: size * 0.5),
  );
}

/// Avatar por iniciais (ou foto local).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.ring = false,
  });

  final UserProfile user;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    final color = palette[user.id.codeUnits.fold<int>(0, (s, c) => s + c) % palette.length];
    final path = user.avatarPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: ring ? Border.all(color: AppColors.surfaceLowest, width: 2) : null,
        image: path != null && File(path).existsSync()
            ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: path != null
          ? null
          : Text(
              user.initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
    );
  }
}

/// Avatares sobrepostos com contador "+N".
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.users,
    this.size = 32,
    this.max = 3,
    this.dark = false,
  });

  final List<UserProfile> users;
  final double size;
  final int max;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final shown = users.take(max).toList();
    final extra = users.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    final overlap = size * 0.32;
    return SizedBox(
      height: size,
      width: count == 0 ? 0 : size + (count - 1) * (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: UserAvatar(user: shown[i], size: size, ring: true),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? AppColors.surfaceLowest : AppColors.primaryContainer,
                  border: Border.all(color: AppColors.surfaceLowest, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.primary : AppColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Trilha de progresso com terminais arredondados.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.color = AppColors.primaryContainer,
    this.background = AppColors.surfaceHighest,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: background),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Cabeçalho de seção com "eyebrow" opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  style: t.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              Text(title, style: t.headlineMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Estado de erro com ação de tentar novamente.
class ErrorIndicator extends StatelessWidget {
  const ErrorIndicator({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimens.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconBadge(
            icon: Icons.cloud_off_outlined,
            background: AppColors.secondaryFixed,
            foreground: AppColors.secondary,
            size: 56,
          ),
          const SizedBox(height: Dimens.spaceMd),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Dimens.spaceMd),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
          ),
        ],
      ),
    ),
  );
}

/// Indicador de carregamento centralizado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.primaryContainer),
  );
}

/// Logotipo "Serene" (folha em seixo).
class SereneLogo extends StatelessWidget {
  const SereneLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.primaryFixed,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.spa, size: size * 0.55, color: AppColors.primary),
  );
}

/// Barra superior padrão: logo, marca, streak e avatar.
class SereneTopBar extends StatelessWidget {
  const SereneTopBar({
    super.key,
    required this.user,
    this.streak,
    this.onAvatarTap,
  });

  final UserProfile? user;
  final int? streak;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Dimens.margin, 8, Dimens.margin, 8),
    child: Row(
      children: [
        const SereneLogo(size: 32),
        const SizedBox(width: 10),
        Text(
          'Serene',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (streak != null) ...[
          StreakPill(days: streak!),
          const SizedBox(width: 10),
        ],
        if (user != null)
          GestureDetector(
            onTap: onAvatarTap,
            child: UserAvatar(user: user!, size: 38, ring: true),
          ),
      ],
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String errorMessage(Object? error) =>
    error?.toString().replaceFirst('Exception: ', '') ??
    'Algo não saiu como esperado.';
