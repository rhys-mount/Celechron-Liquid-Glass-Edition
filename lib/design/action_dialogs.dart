import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required T initialValue,
  required Widget Function(BuildContext, ValueChanged<T>) builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  var draft = initialValue;
  return showCupertinoModalPopup<T>(
    context: context,
    semanticsDismissible: true,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                Expanded(
                  child: Text(title, textAlign: TextAlign.center),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: const Text('完成',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(
              height: math.min(240, MediaQuery.sizeOf(context).height * 0.48),
              child: builder(context, (value) => draft = value),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<DateTime?> showDatePickerSheet(
  BuildContext context, {
  required String title,
  required DateTime initialValue,
  CupertinoDatePickerMode mode = CupertinoDatePickerMode.dateAndTime,
}) =>
    showPickerSheet<DateTime>(
      context,
      title: title,
      initialValue: initialValue,
      builder: (context, update) => CupertinoDatePicker(
        initialDateTime: initialValue,
        mode: mode,
        use24hFormat: true,
        onDateTimeChanged: update,
      ),
    );
