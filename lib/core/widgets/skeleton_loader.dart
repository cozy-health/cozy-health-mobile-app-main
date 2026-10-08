import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.height = 72,
    this.width,
    this.radius = 16,
  });
  final double height;
  final double? width;
  final double radius;
  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: .4,
        end: .7,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: .7,
        end: .4,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
  ]).animate(_controller);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: ExcludeSemantics(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    ),
  );
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(24),
    itemCount: count,
    itemBuilder: (_, _) => const SkeletonLoader(),
    separatorBuilder: (_, _) => const SizedBox(height: 16),
  );
}
