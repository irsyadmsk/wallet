import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';

/// Adaptive ART+ Icon Widget.
///
/// Automatically adapts its geometric silhouette (Squircle, Circle, Hexagon,
/// Rounded Box, Stadium) to the user's ART+ preference in Settings, or an
/// explicit [shapeOverride].
class ArtIcon extends StatelessWidget {
  const ArtIcon({
    super.key,
    this.size = 44,
    this.shapeOverride,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.imagePath,
    this.emoji,
    this.child,
    this.showAura = false,
    this.padding,
  });

  /// Total width and height of the icon container.
  final double size;

  /// Optional shape override. If null, reacts to [ThemeController.artShape].
  final ArtShape? shapeOverride;

  /// Background fill color. Defaults to subtle tint or white/surface.
  final Color? backgroundColor;

  /// Border outline color.
  final Color? borderColor;

  /// Border thickness.
  final double borderWidth;

  /// Optional Material icon.
  final IconData? icon;

  /// Color of [icon].
  final Color? iconColor;

  /// Size of [icon]. Defaults to `size * 0.5`.
  final double? iconSize;

  /// Asset image path (e.g. Bank logo or Art Pack icon).
  final String? imagePath;

  /// Emoji string.
  final String? emoji;

  /// Custom content inside the icon container.
  final Widget? child;

  /// Whether to render a soft ambient glow behind the icon.
  final bool showAura;

  /// Content padding. Defaults to proportional padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (shapeOverride != null || !Get.isRegistered<ThemeController>()) {
      final shape = shapeOverride ?? ArtShape.squircle;
      return _buildContainer(context, shape);
    }

    final theme = Get.find<ThemeController>();
    return Obx(() => _buildContainer(context, theme.artShape.value));
  }

  Widget _buildContainer(BuildContext context, ArtShape shape) {
    final colors = context.colors;
    final bg = backgroundColor ?? colors.surfaceAlt;
    final border = borderColor ?? colors.border.withValues(alpha: 0.35);

    Widget innerContent;
    if (child != null) {
      innerContent = child!;
    } else if (emoji != null && emoji!.isNotEmpty) {
      innerContent = Text(
        emoji!,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size * 0.46),
      );
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      innerContent = Image.asset(
        imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          icon ?? Icons.category_rounded,
          color: iconColor ?? colors.primary,
          size: iconSize ?? (size * 0.48),
        ),
      );
    } else {
      innerContent = Icon(
        icon ?? Icons.category_rounded,
        color: iconColor ?? colors.primary,
        size: iconSize ?? (size * 0.48),
      );
    }

    final effectivePadding = padding ?? EdgeInsets.all(size * 0.2);

    Widget shapedContent;
    if (shape == ArtShape.hexagon) {
      shapedContent = CustomPaint(
        painter: HexagonPainter(
          backgroundColor: bg,
          borderColor: border,
          borderWidth: borderWidth,
        ),
        child: ClipPath(
          clipper: const HexagonClipper(),
          child: SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: effectivePadding,
              child: Center(child: innerContent),
            ),
          ),
        ),
      );
    } else {
      final ShapeBorder shapeBorder;
      switch (shape) {
        case ArtShape.squircle:
          // ContinuousRectangleBorder gives the authentic iOS squircle contour
          shapeBorder = ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.44),
            side: borderWidth > 0 ? BorderSide(color: border, width: borderWidth) : BorderSide.none,
          );
          break;
        case ArtShape.circle:
          shapeBorder = CircleBorder(
            side: borderWidth > 0 ? BorderSide(color: border, width: borderWidth) : BorderSide.none,
          );
          break;
        case ArtShape.roundedSquare:
          shapeBorder = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.22),
            side: borderWidth > 0 ? BorderSide(color: border, width: borderWidth) : BorderSide.none,
          );
          break;
        case ArtShape.stadium:
          shapeBorder = StadiumBorder(
            side: borderWidth > 0 ? BorderSide(color: border, width: borderWidth) : BorderSide.none,
          );
          break;
        case ArtShape.hexagon:
          // Handled above
          shapeBorder = const CircleBorder();
          break;
      }

      shapedContent = Material(
        shape: shapeBorder,
        color: bg,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: effectivePadding,
            child: Center(child: innerContent),
          ),
        ),
      );
    }

    if (!showAura) {
      return shapedContent;
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? bg).withValues(alpha: 0.18),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: shapedContent,
    );
  }
}
