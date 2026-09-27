import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Marca do LeuPlace: ícone (carrinho) + wordmark "LeuPlace" e, opcionalmente,
/// a tagline oficial. Reutilizado na splash screen e nas telas de autenticação.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.markSize = 140,
    this.wordmarkFontSize = 40,
    this.showTagline = true,
    this.wordmarkColor,
    this.horizontal = false,
  });

  final double markSize;
  final double wordmarkFontSize;
  final bool showTagline;
  final Color? wordmarkColor;

  /// Ícone ao lado do nome (para cabeçalhos compactos) em vez de empilhado
  /// verticalmente (usado na splash e nas telas de autenticação).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final leuColor = wordmarkColor ?? AppColors.textDark;

    final mark = Image.asset(
      'assets/images/leuplace_mark.png',
      width: markSize,
      height: markSize,
    );

    final wordmark = RichText(
      text: TextSpan(
        style: AppTextStyles.displayBold.copyWith(
          fontSize: wordmarkFontSize,
          height: 1,
        ),
        children: [
          TextSpan(text: 'Leu', style: TextStyle(color: leuColor)),
          const TextSpan(text: 'Place', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    );

    if (horizontal) {
      // O meio das letras maiúsculas fica exatamente no meio da altura do
      // carrinho (a arte está centralizada na imagem; a altura das
      // maiúsculas da Poppins é ~70% do tamanho da fonte).
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          SizedBox(width: markSize * 0.06),
          Baseline(
            baseline: markSize * 0.5 + wordmarkFontSize * 0.35,
            baselineType: TextBaseline.alphabetic,
            child: wordmark,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 8),
        wordmark,
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Compra • Venda • Encontre',
            style: AppTextStyles.bodyRegular.copyWith(color: leuColor),
          ),
        ],
      ],
    );
  }
}
