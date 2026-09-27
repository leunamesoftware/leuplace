import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Fundo levemente creme usado nas telas de abertura e cadastro/login, para
/// dar uma identidade visual consistente sem elementos gráficos chamativos.
/// Ocupa a tela inteira mesmo quando o conteúdo é mais curto que ela.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.cream),
        child: child,
      ),
    );
  }
}
