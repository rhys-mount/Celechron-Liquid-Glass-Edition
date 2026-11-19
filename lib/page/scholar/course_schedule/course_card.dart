import 'package:celechron/design/card_action.dart';
import 'package:celechron/design/custom_colors.dart';
import 'package:celechron/page/scholar/course_detail/course_detail_view.dart';
import 'package:flutter/cupertino.dart';

import 'package:celechron/model/session.dart';

class SessionCard extends StatelessWidget {
  final List<Session> sessionList;
  final Color? backgroundColor;
  final bool hideInfomation;
  final bool compact;

  const SessionCard({
    super.key,
    required this.sessionList,
    this.hideInfomation = false,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor == null
        ? themeAccent(context)
        : CupertinoDynamicColor.resolve(backgroundColor!, context);
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    // Keep white text legible on the brighter dark-mode accent.
    final background = dark && fill.computeLuminance() > 0.183
        ? Color.alphaBlend(const Color(0x28000000), fill)
        : fill;
    final foreground = !dark && background.computeLuminance() > 0.179
        ? CupertinoColors.black
        : CupertinoColors.white;

    String sessionName = "";
    String sessionLocation = "";
    if (!hideInfomation) {
      if (sessionList.length == 1) {
        sessionName = sessionList[0].name;
        sessionLocation = sessionList[0].location ?? '未知地点';
      } else {
        sessionName = "冲突课程\n";
        for (var i in sessionList) {
          sessionName =
              '$sessionName\n${i.time.first}-${i.time.last}: ${i.name}';
        }
      }
    }

    return CardAction(
      onTap: () async {
        if (sessionList.length == 1) {
          await CourseDetailPage.open(context, sessionList[0].id);
        } else {
          final id = await showCupertinoDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text(
                  '要查看哪一个？',
                ),
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s in sessionList)
                      CupertinoButton(
                        minimumSize: Size.square(compact ? 22 : 44),
                        padding: compact
                            ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
                            : const EdgeInsets.all(8),
                        child: Text(
                          s.name,
                          textAlign: TextAlign.center,
                          maxLines: compact ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(s.id);
                        },
                      ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('返回'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            },
          );
          if (id != null && context.mounted) {
            await CourseDetailPage.open(context, id);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: 1.4,
          bottom: 1.4,
          left: 1.4,
          right: 1.4,
        ),
        child: Container(
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: background,
          ),
          child: ClipRect(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 2.0, right: 2.0, top: 2.0, bottom: 2.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      sessionName,
                      textAlign: TextAlign.center,
                      maxLines: sessionList.length == 1
                          ? 3 // 单课程最多3行
                          : (sessionList.length * 2).clamp(2, 6), // 冲突课程最多6行
                      overflow: TextOverflow.ellipsis,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.bold,
                            color: foreground,
                          ),
                    ),
                  ),
                  if (!hideInfomation && sessionLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        sessionLocation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: compact ? 9 : 10,
                              color: foreground,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
