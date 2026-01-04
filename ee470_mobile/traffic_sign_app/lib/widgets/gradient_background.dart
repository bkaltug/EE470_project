import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surface,
                  colorScheme.surface,
                  Color.lerp(colorScheme.surface, colorScheme.primary, 0.05)!,
                ]
              : [
                  colorScheme.surface,
                  Color.lerp(
                    colorScheme.surface,
                    colorScheme.primaryContainer,
                    0.3,
                  )!,
                  Color.lerp(
                    colorScheme.surface,
                    colorScheme.tertiaryContainer,
                    0.2,
                  )!,
                ],
        ),
      ),
      child: child,
    );
  }
}
