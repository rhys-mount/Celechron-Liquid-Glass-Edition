import 'package:extended_sliver/extended_sliver.dart';
import 'package:flutter/cupertino.dart';

/// A pinned filter surface with transparent margins for content scrolling behind it.
class SliverFloatingFilterPanel extends StatelessWidget {
  const SliverFloatingFilterPanel({
    super.key,
    required this.child,
    this.banner,
    this.childOpacity = 0.88,
  });

  final Widget child;
  final Widget? banner;
  final double childOpacity;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context)
                .withValues(alpha: childOpacity),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner case final banner?) banner,
              Padding(padding: const EdgeInsets.all(12), child: child),
            ],
          ),
        ),
      ),
    );
  }
}
