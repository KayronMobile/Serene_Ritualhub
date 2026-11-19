import 'dart:io';

import 'package:flutter/material.dart';

import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/common.dart';
import '../view_models/community_viewmodel.dart';

/// Abre o formulário de check-in fotográfico. Retorna `true` se publicado.
Future<bool?> showCheckInSheet(BuildContext context, CommunityViewModel vm) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CheckInSheet(viewModel: vm),
    );

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({super.key, required this.viewModel});

  final CommunityViewModel viewModel;

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  final _caption = TextEditingController();
  final _tag = TextEditingController();
  String? _photo;

  CommunityViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.createCheckIn.addListener(_onResult);
    vm.pickPhoto.addListener(_onPhoto);
  }

  @override
  void dispose() {
    vm.createCheckIn.removeListener(_onResult);
    vm.pickPhoto.removeListener(_onPhoto);
    _caption.dispose();
    _tag.dispose();
    super.dispose();
  }

  void _onPhoto() {
    final r = vm.pickPhoto.result;
    if (r == null || !mounted) return;
    switch (r) {
      case Ok<String?>():
        if (r.value != null) setState(() => _photo = r.value);
      case Error<String?>():
        showSnack(context, errorMessage(r.error));
    }
    vm.pickPhoto.clearResult();
  }

  void _onResult() {
    final r = vm.createCheckIn.result;
    if (r == null || !mounted) return;
    if (r is Error<void>) {
      showSnack(context, errorMessage(r.error));
    } else {
      Navigator.pop(context, true);
    }
    vm.createCheckIn.clearResult();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = vm.selected;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimens.margin,
        0,
        Dimens.margin,
        MediaQuery.viewInsetsOf(context).bottom + Dimens.spaceLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Check-in do dia', style: t.headlineMedium),
            if (c != null)
              Text(
                '${c.title} · Dia ${c.currentDay(vm.now)}/${c.durationDays}',
                style: t.bodySmall,
              ),
            const SizedBox(height: Dimens.spaceLg),
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radius),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_photo!), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () => setState(() => _photo = null),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppColors.surfaceContainer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PickButton(
                              icon: Icons.photo_camera_outlined,
                              label: 'Câmera',
                              onTap: () => vm.pickPhoto.execute(true),
                            ),
                            const SizedBox(width: Dimens.spaceLg),
                            _PickButton(
                              icon: Icons.photo_library_outlined,
                              label: 'Galeria',
                              onTap: () => vm.pickPhoto.execute(false),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextField(
              controller: _caption,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Como foi seu dia no desafio?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: Dimens.spaceMd),
            TextField(
              controller: _tag,
              decoration: const InputDecoration(
                hintText: 'Selo da foto (ex.: Sem Açúcar Adicionado)',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
            ),
            const SizedBox(height: Dimens.spaceLg),
            ListenableBuilder(
              listenable: vm.createCheckIn,
              builder: (context, _) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: vm.createCheckIn.running
                    ? null
                    : () => vm.createCheckIn.execute((
                        caption: _caption.text,
                        photoPath: _photo,
                        tag: _tag.text,
                      )),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Publicar check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(Dimens.radius),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, size: 56),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    ),
  );
}
