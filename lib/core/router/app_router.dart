import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../constants/route_names.dart';
import '../providers/router_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    routes: [
      GoRoute(
        path: RouteNames.menu,
        name: RouteNames.menu,
        pageBuilder: (context, state) => _buildPage(
          state,
          const MenuScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.game,
        name: RouteNames.game,
        pageBuilder: (context, state) {
          final difficultyName = state.uri.queryParameters['difficulty'];
          final slot = int.tryParse(state.uri.queryParameters['slot'] ?? '');
          return _buildPage(
            state,
            GameScreen(
              difficultyName: difficultyName,
              savedSlot: slot,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.settings,
        name: RouteNames.settings,
        pageBuilder: (context, state) => _buildPage(
          state,
          const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.leaderboard,
        name: RouteNames.leaderboard,
        pageBuilder: (context, state) => _buildPage(
          state,
          const LeaderboardScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.shop,
        name: RouteNames.shop,
        pageBuilder: (context, state) => _buildPage(
          state,
          const ShopScreen(),
        ),
      ),
    ],
    initialLocation: RouteNames.menu,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.handleRedirect,
  );
});

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}
