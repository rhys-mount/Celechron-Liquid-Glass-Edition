import 'package:celechron/design/card_action.dart';
import 'package:flutter/cupertino.dart';

class TwoLineCard extends StatelessWidget {
  final String title;
  final String content;
  final String? extraContent;
  final bool withColoredFont;
  final bool hideAccentBar;
  final bool animate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final CupertinoDynamicColor backgroundColor;
  final bool transparent;
  final bool mutedTint;
  final double? height;
  final double? width;

  const TwoLineCard({
    super.key,
    required this.title,
    required this.content,
    this.extraContent,
    this.animate = false,
    this.withColoredFont = false,
    this.hideAccentBar = false,
    this.onTap,
    this.onLongPress,
    this.backgroundColor = CupertinoColors.systemBackground,
    this.transparent = false,
    this.mutedTint = false,
    this.height,
    this.width,
  });

  static Widget dummy(String title, String content) =>
      const TwoLineCard(title: 'title', content: 'content');

  @override
  Widget build(BuildContext context) {
    var brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.of(context).platformBrightness;

    if (transparent) {
      return Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // add a colored edge
          children: [
            Text(title,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: const Color.fromRGBO(0, 0, 0, 0),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    )),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  content,
                  style:
                      CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                            color: const Color.fromRGBO(0, 0, 0, 0),
                          ),
                ),
                if (extraContent != null)
                  Text(
                    ' / ${extraContent}',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(
                          fontSize: 12,
                          fontFeatures: [const FontFeature.tabularFigures()],
                          color: const Color.fromRGBO(0, 0, 0, 0),
                        ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final tint = CupertinoDynamicColor.resolve(backgroundColor, context);
    final background = mutedTint
        ? Color.alphaBlend(
            tint.withValues(alpha: brightness == Brightness.dark ? 0.12 : 0.48),
            CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
          )
        : brightness == Brightness.dark
            ? CupertinoColors.secondarySystemFill
            : tint;
    var core = Container(
      height: height,
      width: width,
      padding: EdgeInsets.all(mutedTint ? 11 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background,
        // boxShadow
        boxShadow: mutedTint
            ? const []
            : const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // add a colored edge
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: mutedTint
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .color!
                            .withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          withColoredFont || hideAccentBar
              ? const SizedBox(height: 4)
              : SizedBox(
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                          backgroundColor, context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  content,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color:
                            (withColoredFont && brightness == Brightness.dark)
                                ? CupertinoDynamicColor.resolve(
                                    backgroundColor, context)
                                : CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .color,
                      ),
                ),
                if (extraContent != null)
                  Text(
                    ' / ${extraContent}',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(
                          fontSize: 12,
                          color:
                              (withColoredFont && brightness == Brightness.dark)
                                  ? CupertinoDynamicColor.resolve(
                                      backgroundColor, context)
                                  : CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .color,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return CardAction(
      onTap: onTap,
      onLongPress: onLongPress,
      pressFeedback: animate,
      child: core,
    );
  }
}
