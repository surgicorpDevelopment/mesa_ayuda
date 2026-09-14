import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppSpacing.radiusSm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.slate200,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: AppColors.slate100);
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.slate200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 14, width: 220),
            SizedBox(height: 10),
            AppSkeleton(height: 12, width: 140),
            SizedBox(height: 14),
            Row(
              children: [
                AppSkeleton(height: 22, width: 80, radius: 20),
                SizedBox(width: 8),
                AppSkeleton(height: 22, width: 64, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
