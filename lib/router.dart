import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/perfil_page.dart';
import 'pages/productividad_page.dart';
import 'pages/proyectos_pages.dart';
import 'pages/shell_scaffold.dart';
import 'pages/tareas_page.dart';
import 'pages/tickets_pages.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';
      if (auth.loading) return null;
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';

      final loc = state.matchedLocation;
      final canSeeProyectos = auth.user?.isDesarrollador == true;
      if (loggedIn && !canSeeProyectos && loc.startsWith('/proyectos')) {
        return '/tickets';
      }
      if (loggedIn && !canSeeProyectos && loc.startsWith('/tareas')) {
        return '/tickets';
      }
      if (loggedIn && !canSeeProyectos && loc.startsWith('/reportes')) {
        return '/tickets';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            ShellScaffold(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/tickets',
            builder: (context, state) {
              final mine = state.uri.queryParameters['mine'] == '1';
              final unassigned = state.uri.queryParameters['unassigned'] == '1';
              return TicketsListPage(
                onlyAssignedToMe: mine,
                onlyUnassigned: unassigned,
              );
            },
          ),
          GoRoute(
            path: '/tickets/nuevo',
            builder: (_, state) {
              final pId = state.uri.queryParameters['proyecto'];
              return TicketFormPage(
                proyectoId: pId != null ? int.tryParse(pId) : null,
              );
            },
          ),
          GoRoute(
            path: '/tickets/:id',
            builder: (_, state) =>
                TicketDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/tareas',
            builder: (_, state) {
              final estado = state.uri.queryParameters['estado'] ?? 'pendiente';
              final normalized =
                  estado == 'en_progreso' ? 'en_progreso' : 'pendiente';
              return MisTareasPage(estado: normalized);
            },
          ),
          GoRoute(
            path: '/proyectos',
            builder: (_, __) => const ProyectosListPage(),
          ),
          GoRoute(
            path: '/proyectos/nuevo',
            builder: (_, __) => const ProyectoFormPage(),
          ),
          GoRoute(
            path: '/proyectos/:id',
            builder: (_, state) =>
                ProyectoDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/reportes',
            builder: (_, __) => const ProductividadPage(),
          ),
          GoRoute(path: '/perfil', builder: (_, __) => const PerfilPage()),
        ],
      ),
    ],
  );
}
