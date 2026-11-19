import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../themes/colors.dart';

/// Estrutura com a barra de navegação inferior (Hoje, Rituais, Comunidade,
/// Progresso). Cada aba mantém seu próprio estado via
/// `StatefulShellRoute.indexedStack`.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.wb_sunny_outlined, Icons.wb_sunny, 'Hoje'),
    (Icons.play_circle_outline, Icons.play_circle, 'Rituais'),
    (Icons.groups_outlined, Icons.groups, 'Comunidade'),
    (Icons.insights_outlined, Icons.insights, 'Progresso'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x0F1F2923),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: AppColors.surfaceLowest,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            for (final (icon, selected, label) in _items)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
