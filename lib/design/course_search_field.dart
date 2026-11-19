import 'dart:math' as math;

import 'package:celechron/design/liquid_glass/glass_appearance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The same search surface is a link on Scholar and an input on Search.
class CourseSearchField extends StatelessWidget {
  const CourseSearchField({
    super.key,
    required this.onChanged,
    this.focusNode,
  }) : onPressed = null;

  const CourseSearchField.launcher({super.key, required this.onPressed})
      : onChanged = null,
        focusNode = null;

  static const placeholder = '搜索课程名称';
  static double height(BuildContext context) =>
      math.max(50, MediaQuery.textScalerOf(context).scale(17) * 1.2 + 24);

  final ValueChanged<String>? onChanged;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .copyWith(height: 1.2, fontSize: 17);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final extent = height(context);
    final field = CourseSearchSurface(
      height: extent,
      child: CupertinoSearchTextField(
        focusNode: focusNode,
        placeholder: placeholder,
        placeholderStyle: style.copyWith(color: secondary),
        style: style,
        backgroundColor: CupertinoColors.transparent,
        borderRadius: BorderRadius.circular(extent / 2),
        itemColor: secondary,
        itemSize: 20,
        suffixInsets: const EdgeInsetsDirectional.only(end: 10),
        prefixInsets: const EdgeInsetsDirectional.only(start: 15, end: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        onChanged: onChanged,
      ),
    );
    if (onPressed == null) return field;

    return Semantics(
      label: placeholder,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: ExcludeFocus(
          child: ExcludeSemantics(child: IgnorePointer(child: field)),
        ),
      ),
    );
  }
}

/// Keeps the same capsule outline when Liquid Glass is disabled or unavailable.
class CourseSearchSurface extends StatelessWidget {
  const CourseSearchSurface({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(height: height, child: child);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: content,
    );
    if (!Get.isRegistered<GlassAppearance>()) return fallback;
    final appearance = Get.find<GlassAppearance>();
    if (!appearance.available) return fallback;
    return Obx(() => appearance.enabled.value
        ? GlassContainer(
            height: height,
            shape: LiquidRoundedRectangle(borderRadius: height / 2),
            padding: EdgeInsets.zero,
            useOwnLayer: true,
            quality: defaultTargetPlatform == TargetPlatform.android
                ? GlassQuality.minimal
                : GlassAppearance.quality,
            child: content,
          )
        : fallback);
  }
}
