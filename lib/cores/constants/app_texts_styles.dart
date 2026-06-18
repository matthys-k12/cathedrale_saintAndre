import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Titres : Playfair Display avec fallbacks système robustes
  static TextStyle get heading1 => GoogleFonts.playfairDisplay(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textTitle, height: 1.3,
  ).copyWith(fontFamilyFallback: const ['Georgia', 'serif', 'Roboto', 'sans-serif']);

  static TextStyle get heading2 => GoogleFonts.playfairDisplay(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textTitle, height: 1.35,
  ).copyWith(fontFamilyFallback: const ['Georgia', 'serif', 'Roboto', 'sans-serif']);

  static TextStyle get heading3 => GoogleFonts.playfairDisplay(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textTitle, height: 1.4,
  ).copyWith(fontFamilyFallback: const ['Georgia', 'serif', 'Roboto', 'sans-serif']);

  static TextStyle get headingOnDark => GoogleFonts.playfairDisplay(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textOnDark, height: 1.3,
  ).copyWith(fontFamilyFallback: const ['Georgia', 'serif', 'Roboto', 'sans-serif']);

  // Corps de texte : police système (sans-serif = Roboto sur Android)
  // Roboto gère nativement NFC et NFD et tout l'Unicode Latin étendu
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textBody, height: 1.6,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textBody, height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static TextStyle get subtitle => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static TextStyle get button => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 15, fontWeight: FontWeight.w700,
    color: AppColors.textOnDark, letterSpacing: 0.8,
  );

  static TextStyle get buttonSmall => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textOnDark, letterSpacing: 0.5,
  );

  static TextStyle get fieldLabel => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 1.2,
  );

  static TextStyle get inputText => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textTitle,
  );

  static TextStyle get inputHint => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get quote => GoogleFonts.playfairDisplay(
    fontSize: 14, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.textBody, height: 1.7,
  ).copyWith(fontFamilyFallback: const ['Georgia', 'serif', 'Roboto', 'sans-serif']);

  static TextStyle get badge => const TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textOnDark, letterSpacing: 0.8,
  );

  static TextStyle get label => fieldLabel;
}
