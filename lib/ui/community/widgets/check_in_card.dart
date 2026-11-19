import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/models/challenge.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../../core/ui/visuals.dart';

/// Card do feed de check-ins fotográficos.
class CheckInCard extends StatefulWidget {
  const CheckInCard({
    super.key,
    required this.checkIn,
    required this.challenge,
    required this.now,
    required this.onReact,
    required this.onComment,
  });

  final CheckIn checkIn;
  final Challenge challenge;
  final DateTime now;
  final void Function(Reaction reaction) onReact;
  final void Function(String text) onComment;

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  final _comment = TextEditingController();
  bool _showComments = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _send() {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    widget.onComment(text);
    _comment.clear();
    FocusScope.of(context).unfocus();
    setState(() => _showComments = true);
  }

  List<Reaction> get _visibleReactions {
    final c = widget.checkIn;
    final defaults = switch (widget.challenge.category) {
      ChallengeCategory.hydration => [Reaction.water, Reaction.fire],
      _ => [Reaction.cheer, Reaction.inspiring],
    };
    final withCounts = Reaction.values.where(
      (r) => (c.reactions[r] ?? 0) > 0 || c.myReactions.contains(r),
    );
    return {...withCounts, ...defaults}.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = widget.checkIn;
    final day = Dates.daysBetween(widget.challenge.startDate, c.createdAt) + 1;
    return SereneCard(
      padding: const EdgeInsets.all(Dimens.spaceMd + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: c.author, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.author.name, style: t.titleSmall),
                    Text(
                      [
                        Dates.relative(c.createdAt, widget.now),
                        if (c.context != null) c.context!,
                      ].join(' • '),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              PillBadge(
                label: 'Dia $day/${widget.challenge.durationDays}',
                dense: true,
                background: AppColors.surfaceContainer,
              ),
            ],
          ),
          const SizedBox(height: Dimens.spaceMd),
          _Photo(checkIn: c, category: widget.challenge.category),
          if (c.caption.isNotEmpty) ...[
            const SizedBox(height: Dimens.spaceMd),
            Text('“${c.caption}”', style: t.bodyMedium),
          ],
          const SizedBox(height: Dimens.spaceMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _visibleReactions)
                _ReactionChip(
                  reaction: r,
                  count: c.reactions[r] ?? 0,
                  mine: c.myReactions.contains(r),
                  onTap: () => widget.onReact(r),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _showComments = !_showComments),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16),
                      const SizedBox(width: 6),
                      Text('${c.comments.length}', style: t.labelMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showComments && c.comments.isNotEmpty) ...[
            const SizedBox(height: Dimens.spaceSm),
            for (final cm in c.comments)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(user: cm.author, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: '${cm.author.firstName} ',
                          style: t.labelLarge,
                          children: [
                            TextSpan(text: cm.text, style: t.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: Dimens.spaceMd),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    style: t.bodySmall,
                    decoration: const InputDecoration(
                      hintText: 'Deixar uma palavra de força...',
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(36, 36),
                  ),
                  onPressed: _send,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.checkIn, required this.category});

  final CheckIn checkIn;
  final ChallengeCategory category;

  @override
  Widget build(BuildContext context) {
    final path = checkIn.photoPath;
    final hasFile = path != null && File(path).existsSync();
    final tint = Visuals.categoryTint(category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.radius),
      child: AspectRatio(
        aspectRatio: hasFile ? 4 / 3 : 16 / 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasFile)
              Image.file(File(path), fit: BoxFit.cover)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tint.background, AppColors.surfaceLow],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Visuals.categoryIcon(category),
                    size: 48,
                    color: tint.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ),
            if (checkIn.tag != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pine.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Visuals.categoryIcon(category),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        checkIn.tag!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.count,
    required this.mine,
    required this.onTap,
  });

  final Reaction reaction;
  final int count;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: mine ? AppColors.primaryFixed : AppColors.surfaceLow,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '${reaction.emoji} ${reaction.label}${count > 0 ? ' $count' : ''}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    ),
  );
}
