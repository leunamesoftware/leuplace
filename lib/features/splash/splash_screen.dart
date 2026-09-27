import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';

/// Tela de abertura do app: mostra a marca enquanto o estado de autenticação
/// é resolvido, então navega para a Home ou para o fluxo de login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [Color(0xFFFFF7EE), Color(0xFFFFD9AE), Color(0xFFFFA95E)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const AppLogo(
                markSize: 150,
                wordmarkFontSize: 44,
                wordmarkColor: AppColors.secondary,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white70,
                    valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Carregando...',
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
