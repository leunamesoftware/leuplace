import 'package:flutter/material.dart';

/// Fundo levemente creme usado nas telas de abertura e cadastro/login, para
/// dar uma identidade visual consistente sem elementos gráficos chamativos.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF7EE)),
      child: child,
    );
  }
}
