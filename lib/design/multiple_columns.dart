import 'package:flutter/cupertino.dart';
import 'card_action.dart';

class MultipleColumns extends StatelessWidget {
  final List<Widget> contents;
  final List<String> titles;
  final List<VoidCallback?> onTaps;
  final Color color;

  const MultipleColumns({
    super.key,
    required this.contents,
    required this.titles,
    required this.onTaps,
    this.color = CupertinoColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = titles.length;

    var children = <Widget>[];
    for (var i = 0; i < columnCount; i++) {
      children.add(
        _ColumnWidget(
          content: contents[i],
          title: titles[i],
          onTap: onTaps[i],
          color: color,
        ),
      );
      children.add(const _VerticalLine(color: CupertinoColors.systemFill));
    }
    children.removeLast();

    return SizedBox(
        child: Row(
      children: children,
    ));
  }
}

class _ColumnWidget extends StatelessWidget {
  final Widget content;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _ColumnWidget({
    required this.content,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: CardAction(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            content,
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 3,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CupertinoColors.label
                        .resolveFrom(context)
                        .withValues(alpha: 0.68),
                    fontSize: 14,
                  ),
                ),
                if (onTap != null)
                  Icon(CupertinoIcons.chevron_forward,
                      size: 10,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context)),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

class _VerticalLine extends StatelessWidget {
  final Color color;

  const _VerticalLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: color,
    );
  }
}
