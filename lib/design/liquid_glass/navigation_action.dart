import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
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
              fontSize: 16,
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

class NavigationActionGroup extends StatelessWidget {
  const NavigationActionGroup({super.key, required this.actions});

  final List<({IconData icon, String label, VoidCallback onPressed})> actions;

  @override
  Widget build(BuildContext context) {
    Widget buttons({Color? iconColor}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions)
              CupertinoButton(
                minimumSize: const Size.square(44),
                padding: EdgeInsets.zero,
                onPressed: action.onPressed,
                child: Icon(
                  action.icon,
                  size: 22,
                  color: iconColor,
                  semanticLabel: action.label,
                ),
              ),
          ],
        );
    if (!Get.isRegistered<GlassAppearance>()) return buttons();
    final appearance = Get.find<GlassAppearance>();
    if (!appearance.available) return buttons();

    return Obx(() => appearance.enabled.value
        ? GlassContainer(
            width: 44.0 * actions.length,
            height: 44,
            padding: EdgeInsets.zero,
            shape: const LiquidRoundedRectangle(borderRadius: 22),
            useOwnLayer: true,
            quality: defaultTargetPlatform == TargetPlatform.android
                ? GlassQuality.minimal
                : GlassAppearance.quality,
            child:
                buttons(iconColor: CupertinoColors.label.resolveFrom(context)),
          )
        : buttons());
  }
}
