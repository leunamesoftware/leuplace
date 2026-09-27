import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/route_paths.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/decorative_background.dart';
import '../../widgets/pill_button.dart';
import 'widgets/google_mark.dart';

/// Tela de boas-vindas: apresenta o LeuPlace e dá entrada no fluxo de login
/// (Google ou e-mail) ou de cadastro.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _googleSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Login com Google em breve.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
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
                'Produtos novos e usados da sua região,\nde forma simples, rápida e segura.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Row(
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
                      label: 'Compra e venda\ncom mais segurança',
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
              const SizedBox(height: 28),
              PillButton(
                label: 'Entrar com o Google',
                icon: const GoogleMark(),
                onPressed: () => _googleSoon(context),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Entrar com e-mail',
                filled: false,
                icon: const Icon(Icons.mail_rounded, color: AppColors.primary),
                onPressed: () => context.push(RoutePaths.login),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Ainda não tem uma conta?',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(RoutePaths.register),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ],
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
