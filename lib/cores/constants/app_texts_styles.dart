import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {

  // ── TITRES (Playfair Display — serif, noir comme demandé) ────
  static TextStyle get heading1 => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,  // Noir pur
    height: 1.3,
  );

  static TextStyle get heading2 => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.35,
  );

  static TextStyle get heading3 => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.4,
  );

  // Titres sur fond coloré/sombre → blanc
  static TextStyle get headingOnDark => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    height: 1.3,
  );

  // ── CORPS (DM Sans — lisible, gris foncé comme demandé) ──────

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,  // Gris foncé pour sous-titres
    height: 1.4,
  );

  // Sous-titre — gris foncé comme demandé par le client
  static TextStyle get subtitle => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSubtitle,   // #424242 gris foncé
    height: 1.5,
  );

  // ── BOUTONS ───────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: 0.8,
  );

  static TextStyle get buttonSmall => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
    letterSpacing: 0.5,
  );

  // ── LABELS (champs de formulaire) ────────────────────────────

  static TextStyle get fieldLabel => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSubtitle,
    letterSpacing: 1.2,
  );

  static TextStyle get inputText => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textTitle,
  );

  static TextStyle get inputHint => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── CITATION (italique) ───────────────────────────────────────

  static TextStyle get quote => GoogleFonts.playfairDisplay(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.textBody,
    height: 1.7,
  );

  // ── BADGE ─────────────────────────────────────────────────────

  static TextStyle get badge => GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: 0.8,
  );
}