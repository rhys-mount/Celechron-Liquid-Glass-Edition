import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_appearance.dart';

class NavigationAction extends StatelessWidget {
  const NavigationAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.fallback,
  });

  const NavigationAction.text({
    super.key,
    required this.label,
    required this.onPressed,
  })  : icon = null,
        fallback = null;

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final actionIcon = icon;
    final text = actionIcon == null
        ? Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          )
        : null;
    final cupertino = fallback ??
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: text ?? Icon(actionIcon, semanticLabel: label),
        );
    if (!Get.isRegistered<GlassAppearance>()) return cupertino;

    final appearance = Get.find<GlassAppearance>();
    if (!appearance.available) return cupertino;

    return Obx(() {
      if (!appearance.enabled.value) return cupertino;
      if (text != null) {
        return GlassButton.custom(
          onTap: onPressed ?? () {},
          enabled: onPressed != null,
          label: label,
          height: 44,
          shape: const LiquidRoundedRectangle(borderRadius: 22),
          useOwnLayer: true,
          quality: GlassAppearance.quality,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: text,
            ),
          ),
        );
      }
      return GlassIconButton(
        icon: Icon(actionIcon),
        semanticLabel: label,
        onPressed: onPressed,
        useOwnLayer: true,
        quality: GlassAppearance.quality,
      );
    });
  }
}
