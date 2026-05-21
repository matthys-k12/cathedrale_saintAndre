import 'package:flutter/material.dart';
import 'app_colors.dart';

// Utilitaires pour appliquer les dégradés facilement
// dans les widgets Flutter

class AppGradients {

  // Dégradé sur un Container
  static BoxDecoration heroBox({
    BorderRadius? borderRadius,
  }) => BoxDecoration(
    gradient: AppColors.gradientHero,
    borderRadius: borderRadius ?? BorderRadius.circular(16),
  );

  static BoxDecoration goldBox({
    BorderRadius? borderRadius,
  }) => BoxDecoration(
    gradient: AppColors.gradientGold,
    borderRadius: borderRadius ?? BorderRadius.circular(16),
  );

  static BoxDecoration bleuBox({
    BorderRadius? borderRadius,
  }) => BoxDecoration(
    gradient: AppColors.gradientBleu,
    borderRadius: borderRadius ?? BorderRadius.circular(16),
  );

  static BoxDecoration greenBox({
    BorderRadius? borderRadius,
  }) => BoxDecoration(
    gradient: AppColors.gradientGreen,
    borderRadius: borderRadius ?? BorderRadius.circular(16),
  );

  static BoxDecoration orangeBox({
    BorderRadius? borderRadius,
  }) => BoxDecoration(
    gradient: AppColors.gradientOrange,
    borderRadius: borderRadius ?? BorderRadius.circular(16),
  );

  // Overlay sombre sur image (pour lisibilité du texte)
  static BoxDecoration imageOverlay({
    String? imageUrl,
    BorderRadius? borderRadius,
    double opacity = 0.5,
  }) => BoxDecoration(
    borderRadius: borderRadius ?? BorderRadius.circular(16),
    image: imageUrl != null ? DecorationImage(
      image: NetworkImage(imageUrl),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(opacity),
        BlendMode.darken,
      ),
    ) : null,
  );
}