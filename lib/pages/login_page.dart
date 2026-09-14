import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    if (ok) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FB), Color(0xFFF7FAFC), Color(0xFFE8EEF5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: AppSpacing.shadowLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.navy700,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo_surgi.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 28,
                                  height: 28,
                                  color: AppColors.accent,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'S',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SURGICORP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Bienvenido(a)',
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
                          color: AppColors.brand600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mesa de Ayuda',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Por favor, ingrese sus credenciales',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _userCtrl,
                        label: 'Usuario',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'Contraseña',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.slate500,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Recuérdame',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.brand600,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: AppTypography.textTheme.bodySmall?.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Ingresar',
                        expanded: true,
                        loading: auth.loading,
                        onPressed: auth.loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}
