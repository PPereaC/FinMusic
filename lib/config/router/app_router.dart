import 'package:go_router/go_router.dart';

import '../../presentation/screens/screens.dart';
import '../../presentation/views/views.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => RootScreen(navigationShell: navigationShell),
      branches: [

        // Inicio
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeView(),
            )
          ]
        ),

        // Librería
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryView(),
            )
          ]
        ),

        // Ajustes
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsView(),
            )
          ]
        ),
      ],
    ),

    // Full Player Screen
    GoRoute(
      path: '/full-player',
      builder: (context, state) => const FullPlayerScreen(),
    )

  ]
);