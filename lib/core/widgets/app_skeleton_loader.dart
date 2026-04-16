/// EduX School Management System
/// Skeleton Loader Widget for list items
library;

import 'package:flutter/material.dart';

/// Skeleton loader for list items with shimmer effect
class AppSkeletonLoader extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  final bool isLoading;
  final Widget? child;
  final double itemHeight;
  final EdgeInsets? padding;

  const AppSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    required this.isLoading,
    this.child,
    this.itemHeight = 72,
    this.padding,
  });

  /// Creates a skeleton loader for a list of items
  factory AppSkeletonLoader.list({
    Key? key,
    int itemCount = 5,
    required bool isLoading,
    Widget? child,
    double itemHeight = 72,
    EdgeInsets? padding,
  }) {
    return AppSkeletonLoader(
      key: key,
      itemCount: itemCount,
      isLoading: isLoading,
      itemHeight: itemHeight,
      padding: padding,
      child: child,
    );
  }

  /// Creates a skeleton loader for a card grid
  factory AppSkeletonLoader.grid({
    Key? key,
    int itemCount = 6,
    required bool isLoading,
    Widget? child,
    double itemHeight = 120,
    EdgeInsets? padding,
  }) {
    return AppSkeletonLoader(
      key: key,
      itemCount: itemCount,
      isLoading: isLoading,
      itemHeight: itemHeight,
      padding: padding,
      itemBuilder: (context, index) => const _SkeletonCard(),
      child: child,
    );
  }

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child ?? const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: widget.padding ?? const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (widget.itemBuilder != null) {
              return _ShimmerWrapper(
                animation: _animation,
                child: widget.itemBuilder!(context, index),
              );
            }
            return _ShimmerWrapper(
              animation: _animation,
              child: _SkeletonListTile(height: widget.itemHeight),
            );
          },
        );
      },
    );
  }
}

class _ShimmerWrapper extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerWrapper({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (animation.value - 0.3).clamp(0, 1),
            animation.value.clamp(0, 1),
            (animation.value + 0.3).clamp(0, 1),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}

class _SkeletonListTile extends StatelessWidget {
  final double height;

  const _SkeletonListTile({this.height = 72});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title skeleton
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle skeleton
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Trailing skeleton
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 100,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual skeleton shapes for custom layouts
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    );
  }
}
