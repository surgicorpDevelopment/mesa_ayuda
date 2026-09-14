import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.hoverable = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hoverable;
  final EdgeInsetsGeometry? margin;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hover = widget.hoverable || widget.onTap != null;
    return MouseRegion(
      onEnter: hover ? (_) => setState(() => _hovered = true) : null,
      onExit: hover ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _hovered ? AppColors.brand600.withValues(alpha: 0.35) : AppColors.slate200,
          ),
          boxShadow: _hovered ? AppSpacing.shadowMd : AppSpacing.shadowSm,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
