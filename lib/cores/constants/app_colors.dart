import 'package:flutter/material.dart';

// Palette éditoriale — inspirée du design "Prions en Église"
// Couleurs solides, pas de dégradés pour l'UI principale
class AppColors {

  // ── Rouge principal (ancre de l'identité) ──────────────────────────
  static const Color primary = Color(0xFFC62828);
  static const Color primaryDark = Color(0xFF8E1F1F);
  static const Color primaryLight = Color(0xFFFCEBEB);

  // ── Marine (headers accueil & compte) ─────────────────────────────
  static const Color navy = Color(0xFF1A237E);
  static const Color navySoft = Color(0xFFE8EAF6);

  // ── Bleu (saint du jour, infos) ───────────────────────────────────
  static const Color bleuMarial = Color(0xFF1565C0);
  static const Color bleuMarialLight = Color(0xFF1E88E5);
  static const Color bleuSoft = Color(0xFFE3F2FD);

  // ── Jaune / Or (intention de prière, citations) ───────────────────
  static const Color gold = Color(0xFFFDD835);
  static const Color goldLight = Color(0xFFFFFDE7);
  static const Color goldDark = Color(0xFFF9A825);

  // ── Vert (actualités, dons) ────────────────────────────────────────
  static const Color green = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFF2E7D32);
  static const Color greenSoft = Color(0xFFE8F5E9);

  // ── Violet (casuels) ─────────────────────────────────────────────
  static const Color violet = Color(0xFF5E35B1);
  static const Color violetLight = Color(0xFF7E57C2);
  static const Color violetSoft = Color(0xFFEDE7F6);

  // ── Orange (podcast) ─────────────────────────────────────────────
  static const Color orange = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFF57C00);
  static const Color orangeSoft = Color(0xFFFFF3E0);

  // ── Fond et surfaces ──────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F5F1);      // warm off-white
  static const Color surfaceInput = Color(0xFFF0EDE8);

  // ── Texte ─────────────────────────────────────────────────────────
  static const Color textTitle = Color(0xFF0A0A0A);
  static const Color textSubtitle = Color(0xFF424242);
  static const Color textBody = Color(0xFF424242);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnGold = Color(0xFF0A0A0A);   // noir sur jaune

  // ── Sémantique ────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B5E20);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF1565C0);

  // ── Bordures et ombres ────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E5E5);
  static const Color dividerStrong = Color(0xFFD6D6D6);
  static const Color shadow = Color(0x0F000000);

  // ── Couleurs sémantiques par module ──────────────────────────────
  static const Color colorMesse = Color(0xFFC62828);    // rouge
  static const Color colorCasuels = Color(0xFF5E35B1);  // violet
  static const Color colorDons = Color(0xFF1B5E20);     // vert
  static const Color colorPodcast = Color(0xFFE65100);  // orange
  static const Color colorAnnonces = Color(0xFFC62828); // rouge
  static const Color colorActualites = Color(0xFF1B5E20); // vert
  static const Color colorSaint = Color(0xFF1565C0);    // bleu
  static const Color colorTexte = Color(0xFF1A237E);    // marine

  // ── Dégradés — conservés pour rétrocompatibilité ─────────────────
  // N'utilisez pas ces dégradés dans les nouvelles vues.
  // L'UI principale utilise des couleurs solides uniquement.
  static const LinearGradient gradientHero = LinearGradient(
    colors: [Color(0xFFC62828), Color(0xFF8E1F1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFFDD835), Color(0xFFF9A825)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientBleu = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient gradientGreen = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientOrange = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientVitrail = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFFC62828), Color(0xFFFDD835)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Alias pour compatibilité ──────────────────────────────────────
  static const Color accent = gold;
  static const Color accentLight = goldLight;
  static const Color textPrimary = textTitle;
  static const Color textOnPrimary = textOnDark;
  static const Color red = primary;

  // ── Alias tokens JSX ─────────────────────────────────────────────
  static const Color ink = textTitle;           // #0A0A0A
  static const Color hairlineStrong = dividerStrong; // #D6D6D6
}
