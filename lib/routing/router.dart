import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/view_models/login_viewmodel.dart';
import '../ui/auth/widgets/login_screen.dart';
import '../ui/community/view_models/community_viewmodel.dart';
import '../ui/community/widgets/community_screen.dart';
import '../ui/core/ui/scaffold_with_nav_bar.dart';
import '../ui/core/view_model.dart';
import '../ui/home/view_models/home_viewmodel.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/profile/view_models/profile_viewmodel.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/reminders/view_models/reminders_viewmodel.dart';
import '../ui/reminders/widgets/reminders_screen.dart';
import '../ui/reports/view_models/reports_viewmodel.dart';
import '../ui/reports/widgets/reports_screen.dart';
import '../ui/ritual_builder/view_models/ritual_builder_viewmodel.dart';
import '../ui/ritual_builder/widgets/ritual_builder_screen.dart';
import '../ui/ritual_player/view_models/ritual_player_viewmodel.dart';
import '../ui/ritual_player/widgets/ritual_player_screen.dart';
import '../ui/rituals/view_models/rituals_viewmodel.dart';
import '../ui/rituals/widgets/rituals_screen.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Configuração de rotas.
///
/// Cada rota cria seu ViewModel injetando dependências com `context.read()`
/// e o entrega à View pelo construtor (padrão do guia de arquitetura).
GoRouter router(AuthRepository authRepository) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  refreshListenable: authRepository,
  redirect: (context, state) async {
    final loggedIn = await authRepository.isAuthenticated;
    final loggingIn = state.matchedLocation == Routes.login;
    if (!loggedIn) return loggingIn ? null : Routes.login;
    if (loggingIn) return Routes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (context, state) => ViewModelBuilder(
        create: (c) => LoginViewModel(authRepository: c.read()),
        builder: (_, vm) => LoginScreen(viewModel: vm),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          ScaffoldWithNavBar(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => ViewModelBuilder(
                create: (c) => HomeViewModel(
                  authRepository: c.read(),
                  ritualRepository: c.read(),
                  healthRepository: c.read(),
                  challengeRepository: c.read(),
                  planReminders: c.read(),
                ),
                builder: (_, vm) => HomeScreen(viewModel: vm),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.rituals,
              builder: (context, state) => ViewModelBuilder(
                create: (c) => RitualsViewModel(ritualRepository: c.read()),
                builder: (_, vm) => RitualsScreen(viewModel: vm),
              ),
              routes: [
                GoRoute(
                  path: 'novo',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => ViewModelBuilder(
                    create: (c) => RitualBuilderViewModel(
                      ritualRepository: c.read(),
                      challengeRepository: c.read(),
                      planReminders: c.read(),
                    ),
                    builder: (_, vm) => RitualBuilderScreen(viewModel: vm),
                  ),
                ),
                GoRoute(
                  path: ':id/editar',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => ViewModelBuilder(
                    create: (c) => RitualBuilderViewModel(
                      ritualId: state.pathParameters['id'],
                      ritualRepository: c.read(),
                      challengeRepository: c.read(),
                      planReminders: c.read(),
                    ),
                    builder: (_, vm) => RitualBuilderScreen(viewModel: vm),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.community,
              builder: (context, state) => ViewModelBuilder(
                create: (c) => CommunityViewModel(
                  authRepository: c.read(),
                  challengeRepository: c.read(),
                  photoService: c.read(),
                ),
                builder: (_, vm) => CommunityScreen(viewModel: vm),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.progress,
              builder: (context, state) => ViewModelBuilder(
                create: (c) => ReportsViewModel(
                  authRepository: c.read(),
                  ritualRepository: c.read(),
                  healthRepository: c.read(),
                  challengeRepository: c.read(),
                  achievementRepository: c.read(),
                  reminderRepository: c.read(),
                  weeklyReport: c.read(),
                  evaluateAchievements: c.read(),
                  planReminders: c.read(),
                ),
                builder: (_, vm) => ReportsScreen(viewModel: vm),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/player/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => ViewModelBuilder(
        create: (c) => RitualPlayerViewModel(
          ritualId: state.pathParameters['id']!,
          ritualRepository: c.read(),
          authRepository: c.read(),
          completeStep: c.read(),
          evaluateAchievements: c.read(),
        ),
        builder: (_, vm) => RitualPlayerScreen(viewModel: vm),
      ),
    ),
    GoRoute(
      path: Routes.reminders,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => ViewModelBuilder(
        create: (c) => RemindersViewModel(
          reminderRepository: c.read(),
          ritualRepository: c.read(),
          planReminders: c.read(),
        ),
        builder: (_, vm) => RemindersScreen(viewModel: vm),
      ),
    ),
    GoRoute(
      path: Routes.profile,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => ViewModelBuilder(
        create: (c) => ProfileViewModel(
          authRepository: c.read(),
          healthRepository: c.read(),
        ),
        builder: (_, vm) => ProfileScreen(viewModel: vm),
      ),
    ),
  ],
);
