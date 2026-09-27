import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/route_paths.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/decorative_background.dart';
import '../../widgets/pill_button.dart';

/// Tela de boas-vindas: apresenta o LeuPlace e dá entrada no login por
/// e-mail ou no cadastro. (Login com Google volta quando o backend suportar.)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecorativeBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(markSize: 120, wordmarkFontSize: 34),
                          const SizedBox(height: 28),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.h1.copyWith(fontSize: 26),
                              children: const [
                                TextSpan(text: 'Compre e venda\n'),
                                TextSpan(
                                  text: 'perto de você',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Produtos novos e usados da sua região,\n'
                            'de forma simples, rápida e segura.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _HighlightCard(
                                  icon: Icons.location_on,
                                  iconColor: AppColors.primary,
                                  label: 'Encontre\nna sua região',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _HighlightCard(
                                  icon: Icons.verified_user,
                                  iconColor: AppColors.secondary,
                                  label: 'Negocie com\nsegurança',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _HighlightCard(
                                  icon: Icons.groups,
                                  iconColor: AppColors.primary,
                                  label: 'Milhares\nde produtos',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          PillButton(
                            label: 'Criar conta grátis',
                            trailing: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => context.push(RoutePaths.register),
                          ),
                          const SizedBox(height: 12),
                          PillButton(
                            label: 'Já tenho conta — Entrar',
                            filled: false,
                            icon: const Icon(
                              Icons.mail_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () => context.push(RoutePaths.login),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
