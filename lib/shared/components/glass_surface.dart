// ignore: deprecated_member_use
import 'dart:ui' show ImageFilter;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Translucent, blurred surface for cards and other floating app content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.child,
    this.semanticContainer = true,
  });

  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final Widget? child;
  final bool semanticContainer;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = shape is RoundedRectangleBorder
        ? (shape as RoundedRectangleBorder)
            .borderRadius
            .resolve(Directionality.of(context))
        : BorderRadius.circular(22);
    final fill = color ?? Theme.of(context).colorScheme.surface;
    final opacity = dark ? .56 : .72;
    final elevationValue = elevation ?? 4;
    final edge = shape is RoundedRectangleBorder
        ? (shape as RoundedRectangleBorder).side
        : BorderSide(color: Colors.white.withValues(alpha: dark ? .24 : .82));

    return Semantics(
      container: semanticContainer,
      child: Container(
        margin: margin ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: (shadowColor ?? Brand.charcoal)
                  .withValues(alpha: dark ? .25 : .08),
              blurRadius: 18 + elevationValue * 2,
              offset: Offset(0, 4 + elevationValue),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: clipBehavior ?? Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill.withValues(alpha: opacity),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: dark ? .12 : .34),
                    (surfaceTintColor ?? Brand.green)
                        .withValues(alpha: dark ? .08 : .025),
                    Colors.white.withValues(alpha: dark ? .035 : .12),
                  ],
                  stops: const [0, .48, 1],
                ),
                border: Border.fromBorderSide(edge),
                borderRadius: radius,
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: shape,
                clipBehavior: clipBehavior ?? Clip.none,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle ambient color fields that make the translucent surfaces read as glass.
class LiquidGlassBackdrop extends StatelessWidget {
  const LiquidGlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [
                        Color(0xFF101B1B),
                        Color(0xFF172322),
                        Color(0xFF121A1E)
                      ]
                    : const [
                        Color(0xFFF1F8F4),
                        Color(0xFFF8FAF9),
                        Color(0xFFEDF5F1)
                      ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -85,
            child: _AmbientOrb(
                color: Brand.green.withValues(alpha: dark ? .2 : .14),
                size: 310),
          ),
          Positioned(
            top: 280,
            left: -160,
            child: _AmbientOrb(
                color:
                    const Color(0xFF9DCDB8).withValues(alpha: dark ? .17 : .22),
                size: 340),
          ),
          Positioned(
            bottom: -165,
            right: -90,
            child: _AmbientOrb(
                color:
                    const Color(0xFFC1DCCF).withValues(alpha: dark ? .12 : .3),
                size: 360),
          ),
        ],
      ),
    );
  }
}

class GlassNavigation extends StatelessWidget {
  const GlassNavigation({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.vertical(top: Radius.circular(24));
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: dark ? .18 : .82))),
        boxShadow: [
          BoxShadow(
              color: Brand.charcoal.withValues(alpha: dark ? .2 : .07),
              blurRadius: 22,
              offset: const Offset(0, -5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: child,
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
