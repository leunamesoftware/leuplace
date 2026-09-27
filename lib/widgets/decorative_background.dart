import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Fundo decorativo (gradiente creme + manchas laranja/roxo) usado nas telas
/// de abertura e cadastro/login, para dar a mesma identidade visual em todo
/// o fluxo de entrada no app.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFFFF7EE)),
          ),
        ),
        Positioned(
          top: -60,
          left: -80,
          child: _blob(220, AppColors.primary.withOpacity(0.18)),
        ),
        Positioned(
          top: -40,
          right: -70,
          child: _blob(180, AppColors.secondary.withOpacity(0.22)),
        ),
        Positioned(
          bottom: -90,
          left: -60,
          child: _blob(200, AppColors.secondary.withOpacity(0.16)),
        ),
        Positioned(
          bottom: -70,
          right: -80,
          child: _blob(220, AppColors.primary.withOpacity(0.20)),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
