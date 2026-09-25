import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../config/app_version.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

class ShellScaffold extends StatefulWidget {
  const ShellScaffold({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  bool _collapsed = false;

  List<_NavItem> _navItems(bool canSeeProyectos) {
    return [
      const _NavItem('Inicio', Icons.home_outlined, Icons.home_rounded, '/'),
      const _NavItem(
        'Tickets',
        Icons.confirmation_number,
        Icons.confirmation_number,
        '/tickets',
      ),
      if (canSeeProyectos)
        const _NavItem(
          'Tareas',
          // task_alt_rounded también se usa en Icon(...) de Reportes/Inicio;
          // así el tree-shake del build web release no lo elimina del font.
          Icons.task_alt_rounded,
          Icons.task_alt_rounded,
          '/tareas',
        ),
      if (canSeeProyectos)
        const _NavItem(
          'Proyectos',
          Icons.folder_outlined,
          Icons.folder_rounded,
          '/proyectos',
        ),
      if (canSeeProyectos)
        const _NavItem(
          'Reportes',
          Icons.insights_outlined,
          Icons.insights_rounded,
          '/reportes',
        ),
      const _NavItem(
        'Perfil',
        Icons.person_outline,
        Icons.person_rounded,
        '/perfil',
      ),
    ];
  }

  int _selectedIndex(List<_NavItem> items) {
    final loc = widget.location;
    for (var i = 0; i < items.length; i++) {
      final path = items[i].path;
      if (path == '/') {
        if (loc == '/' || loc.startsWith('/?')) return i;
        continue;
      }
      if (loc.startsWith(path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canSeeProyectos = user?.isDesarrollador == true;
    final items = _navItems(canSeeProyectos);
    final index = _selectedIndex(items);
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final content = Column(
      children: [
        _Topbar(
          title: 'Mesa de Ayuda',
          userName: user?.fullName,
          onProfile: () => context.go('/perfil'),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    if (!wide) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index.clamp(0, items.length - 1),
          onDestinationSelected: (i) => context.go(items[i].path),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.iconSelected),
                label: item.label,
              ),
          ],
        ),
      );
    }

    final width = _collapsed
        ? AppSpacing.sidebarCollapsed
        : AppSpacing.sidebarExpanded;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.shellSidebar, AppColors.shellSidebarEnd],
              ),
              border: Border(
                right: BorderSide(color: AppColors.shellSidebarBorder),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.shellSidebarBorder),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _collapsed ? 8 : 14,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Durante la animación el ancho cambia antes/después de
                          // `_collapsed`; usamos el espacio real para evitar overflow.
                          final showToggle = constraints.maxWidth >= 120;
                          final toggle = IconButton(
                            tooltip: _collapsed ? 'Expandir' : 'Colapsar',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () =>
                                setState(() => _collapsed = !_collapsed),
                            icon: Icon(
                              _collapsed
                                  ? Icons.menu_open_rounded
                                  : Icons.menu_rounded,
                              size: 22,
                              color: AppColors.white.withValues(alpha: 0.92),
                            ),
                          );

                          // `mark` es solo el isotipo: en el rail colapsado el
                          // logo completo (4.7:1) quedaría de pocos píxeles.
                          Widget logo({
                            required double height,
                            bool mark = false,
                          }) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                mark
                                    ? 'assets/images/logo_surgi_mark.png'
                                    : 'assets/images/logo_surgi_trim.png',
                                height: height,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => SizedBox(
                                  width: height * (mark ? 0.65 : 4.7),
                                  height: height,
                                  child: const Text(
                                    'S',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (!showToggle) {
                            return Center(
                              child: Tooltip(
                                message: 'Expandir',
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _collapsed = false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: logo(height: 28, mark: true),
                                ),
                              ),
                            );
                          }

                          // El logo va centrado en el sidebar; el toggle se ancla
                          // a la derecha para no desplazarlo.
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 34),
                                child: logo(height: 26),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: toggle,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < items.length; i++)
                    _SidebarTile(
                      item: items[i],
                      selected: index == i,
                      onTap: () => context.go(items[i].path),
                    ),
                  const Spacer(),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                      child: InkWell(
                        onTap: () => context.go('/perfil'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.shellSidebarHover,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.shellSidebarBorder,
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final showDetails = constraints.maxWidth >= 100;
                              if (!showDetails) {
                                return Center(
                                  child: AppAvatar(
                                    name: user.fullName,
                                    size: 32,
                                  ),
                                );
                              }
                              return Row(
                                children: [
                                  AppAvatar(name: user.fullName, size: 34),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppColors.white,
                                              ),
                                        ),
                                        Text(
                                          user.area ?? user.username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppColors.shellSidebarMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.iconSelected, this.path);
  final String label;
  final IconData icon;
  final IconData iconSelected;
  final String path;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? AppColors.shellNavSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.shellSidebarHover,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Evita overflow durante la animación del sidebar.
              final showLabel = constraints.maxWidth >= 100;
              return Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
                alignment: showLabel ? null : Alignment.center,
                child: Row(
                  mainAxisAlignment: showLabel
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    if (selected && showLabel)
                      Container(
                        width: 3,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.brand500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    else if (showLabel)
                      const SizedBox(width: 13),
                    Icon(
                      selected ? item.iconSelected : item.icon,
                      size: 20,
                      color: selected
                          ? AppColors.brand500
                          : AppColors.shellSidebarMuted,
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: selected
                                ? AppColors.white
                                : AppColors.shellSidebarMuted,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.title,
    required this.userName,
    required this.onProfile,
  });

  final String title;
  final String? userName;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.shellTopbar,
        border: Border(bottom: BorderSide(color: AppColors.shellTopbarBorder)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.shellTopbarTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppVersion.labelWithBuild,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.shellTopbarTitle.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (ApiConfig.useMock) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'MOCK',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (userName != null) ...[
            Text(
              userName!,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.shellTopbarTitle.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: onProfile,
              borderRadius: BorderRadius.circular(20),
              child: AppAvatar(name: userName!, size: 34),
            ),
          ],
        ],
      ),
    );
  }
}
