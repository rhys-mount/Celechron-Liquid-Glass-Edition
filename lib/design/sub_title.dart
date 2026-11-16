import 'package:flutter/cupertino.dart';

class SubtitleRow extends StatelessWidget {
  final String subtitle;
  final Widget? right;
  final double padHorizontal;
  final double padVertical;
  late final String heroTag = subtitle;
  final double fontSize;
  final bool wrapSubtitle;

  SubtitleRow(
      {super.key,
      required this.subtitle,
      this.right,
      this.padHorizontal = 2,
      this.fontSize = 20,
      this.padVertical = 12,
      this.wrapSubtitle = false});

  @override
  Widget build(BuildContext context) {
    final title = Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(vertical: padVertical),
      child: Hero(
        tag: heroTag,
        child: Text(
          subtitle,
          style: CupertinoTheme.of(context)
              .textTheme
              .navLargeTitleTextStyle
              .copyWith(fontSize: fontSize),
        ),
      ),
    );
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: padHorizontal),
        child: Row(children: [
          if (wrapSubtitle)
            Expanded(child: title)
          else ...[
            title,
            const Spacer(),
          ],
          if (right != null) right!,
        ]));
  }
}

class SubSubtitleRow extends StatelessWidget {
  final String subtitle;
  final Widget? right;
  final double padHorizontal;
  late final String heroTag = subtitle;

  SubSubtitleRow(
      {super.key, required this.subtitle, this.right, this.padHorizontal = 2});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: padHorizontal),
        child: Row(children: [
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Hero(
                tag: heroTag,
                child: Text(
                  subtitle,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navLargeTitleTextStyle
                      .copyWith(fontSize: 18),
                ),
              )),
          const Spacer(),
          right == null ? const SizedBox(height: 0) : right!,
        ]));
  }
}
