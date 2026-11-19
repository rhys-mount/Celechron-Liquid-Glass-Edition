import 'package:celechron/design/card_action.dart';
import 'package:flutter/cupertino.dart';

class RoundRectangleCard extends StatelessWidget {
  final Widget child;
  final Function()? onTap;
  final bool animate;
  final List<BoxShadow> boxShadow;
  final EdgeInsets padding;
  final double cornerRadius;

  const RoundRectangleCard({
    super.key,
    required this.child,
    this.onTap,
    this.animate = true,
    this.padding = const EdgeInsets.all(12),
    this.cornerRadius = 12,
    this.boxShadow = const [
      BoxShadow(
        color: CupertinoColors.systemGrey5,
        spreadRadius: 0,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  });

  const RoundRectangleCard.content({
    super.key,
    required this.child,
    this.onTap,
    this.animate = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  })  : cornerRadius = 16,
        boxShadow = const [
          BoxShadow(
              color: Color(0x14002743), blurRadius: 5, offset: Offset(0, 2)),
        ];

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.of(context).platformBrightness;
    var core = Container(
        padding: padding,
        // decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(12),
        //     // In light mode, color is white; in dark mode, color is black
        //     color: SchedulerBinding
        //                 .instance.platformDispatcher.platformBrightness ==
        //             Brightness.dark
        //         ? CupertinoDynamicColor.resolve(
        //             CupertinoColors.secondarySystemBackground, context)
        //         : CupertinoDynamicColor.resolve(CupertinoColors.white, context),
        //     boxShadow: SchedulerBinding
        //                 .instance.platformDispatcher.platformBrightness ==
        //             Brightness.dark
        //         ? null
        //         : boxShadow),
        // 修改了颜色控制逻辑，应该跟随应用设置而非系统设置
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: brightness == Brightness.dark ? null : boxShadow,
          color: brightness == Brightness.dark
              ? CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground, context)
              : CupertinoDynamicColor.resolve(CupertinoColors.white, context),
        ),
        child: child);
    return CardAction(onTap: onTap, child: core);
  }
}

class RoundRectangleCardWithForehead extends StatelessWidget {
  final Widget child;
  final Widget forehead;
  final Color foreheadColor;
  final Function()? onTap;
  final bool animate;

  const RoundRectangleCardWithForehead({
    super.key,
    required this.child,
    required this.forehead,
    this.foreheadColor = CupertinoColors.systemFill,
    this.onTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: SizedBox(
                child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: CupertinoDynamicColor.resolve(foreheadColor, context),
            boxShadow: const [],
          ),
        ))),
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              forehead,
              RoundRectangleCard(
                onTap: onTap,
                animate: animate,
                boxShadow: const [],
                child: child,
              ),
            ],
          ),
        )
      ],
    );
  }
}
