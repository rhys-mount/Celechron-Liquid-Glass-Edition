import 'package:celechron/design/card_detail_line.dart';
import 'package:celechron/model/todo.dart';
import 'package:celechron/utils/utils.dart';
import 'package:flutter/cupertino.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;

  const TodoCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final foreground = CupertinoColors.label.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(
              todo.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            CardDetailLine(
              CupertinoIcons.clock,
              todo.endTime == null
                  ? '无截止时间'
                  : toStringHumanReadable(todo.endTime!),
              emphasis: true,
            ),
            Text(
              todo.course,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: foreground.withValues(alpha: 0.68), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
