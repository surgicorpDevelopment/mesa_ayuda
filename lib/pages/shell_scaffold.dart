import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
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
        Icons.confirmation_number_outlined,
        Icons.confirmation_number,
        '/tickets',
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
      const _NavItem('Perfil', Icons.person_outline, Icons.person_rounded, '/perfil'),
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

  String _titleFor(List<_NavItem> items, int index) {
    if (index < 0 || index >= items.length) return 'Inicio';
    return items[index].label;
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
          title: _titleFor(items, index),
          userName: user?.fullName,
          onProfile: () => context.go('/perfil'),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
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

    final width = _collapsed ? AppSpacing.sidebarCollapsed : AppSpacing.sidebarExpanded;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(right: BorderSide(color: AppColors.slate200)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _collapsed ? 8 : 16,
                      16,
                      _collapsed ? 8 : 8,
                      8,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Durante la animación el ancho cambia antes/después de
                        // `_collapsed`; usamos el espacio real para evitar overflow.
                        final showBrand = constraints.maxWidth >= 120;
                        final toggle = IconButton(
                          tooltip: _collapsed ? 'Expandir' : 'Colapsar',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => setState(() => _collapsed = !_collapsed),
                          icon: Icon(
                            _collapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                            size: 20,
                            color: AppColors.slate500,
                          ),
                        );

                        if (!showBrand) {
                          return Center(
                            child: Tooltip(
                              message: 'Expandir',
                              child: InkWell(
                                onTap: () => setState(() => _collapsed = false),
                                borderRadius: BorderRadius.circular(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/logo_surgi.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 32,
                                      height: 32,
                                      color: AppColors.navy700,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'S',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo_surgi.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32,
                                  height: 32,
                                  color: AppColors.navy700,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'S',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mesa de Ayuda',
                                style: AppTypography.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            toggle,
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < items.length; i++)
                    _SidebarTile(
                      item: items[i],
                      selected: index == i,
                      onTap: () => context.go(items[i].path),
                    ),
                  const Spacer(),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () => context.go('/perfil'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final showDetails = constraints.maxWidth >= 100;
                              if (!showDetails) {
                                return Center(
                                  child: AppAvatar(name: user.fullName, size: 32),
                                );
                              }
                              return Row(
                                children: [
                                  AppAvatar(name: user.fullName, size: 34),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.textTheme.labelMedium,
                                        ),
                                        Text(
                                          user.area ?? user.username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.textTheme.bodySmall,
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
        color: selected ? AppColors.brand50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Evita overflow durante la animación del sidebar.
              final showLabel = constraints.maxWidth >= 100;
              return Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
                alignment: showLabel ? null : Alignment.center,
                child: Row(
                  mainAxisAlignment:
                      showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    if (selected && showLabel)
                      Container(
                        width: 3,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.brand600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    else if (showLabel)
                      const SizedBox(width: 13),
                    Icon(
                      selected ? item.iconSelected : item.icon,
                      size: 20,
                      color: selected ? AppColors.brand600 : AppColors.slate500,
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: selected ? AppColors.brand600 : AppColors.slate700,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          Text(title, style: AppTypography.textTheme.titleLarge),
          if (ApiConfig.useMock) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
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
            Text(userName!, style: AppTypography.textTheme.bodySmall),
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
