import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_version.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('Sin sesión'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(title: 'Perfil', subtitle: 'Tu cuenta y roles en el gestor'),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(name: user.fullName, size: 64, fontSize: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: AppTypography.textTheme.headlineSmall),
                        Text('@${user.username}', style: AppTypography.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 560;
                  final rows = [
                    _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email.isEmpty ? '—' : user.email),
                    _InfoTile(icon: Icons.apartment_outlined, label: 'Área', value: user.area ?? '—'),
                    _InfoTile(icon: Icons.work_outline, label: 'Puesto', value: user.puesto ?? '—'),
                    _InfoTile(icon: Icons.verified_user_outlined, label: 'Staff', value: user.isStaff ? 'Sí' : 'No'),
                  ];
                  if (wide) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: rows.map((r) => SizedBox(width: (constraints.maxWidth - 16) / 2, child: r)).toList(),
                    );
                  }
                  return Column(children: rows.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: r)).toList());
                },
              ),
              const SizedBox(height: 16),
              Text('Grupos / roles', style: AppTypography.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (user.groups.isEmpty)
                    Text('Sin grupos GP asignados', style: AppTypography.textTheme.bodySmall)
                  else
                    ...user.groups.map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brand600.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          g,
                          style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.brand600),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.info_outline,
                label: 'Versión de la app',
                value: AppVersion.labelWithBuild,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.danger,
          onPressed: () async => auth.logout(),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textTheme.bodySmall),
                Text(value, style: AppTypography.textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
