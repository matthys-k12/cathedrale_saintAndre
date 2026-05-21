import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// NOUVELLE PALETTE — Inspirée des vitraux de la cathédrale
// Demande client : couleurs gaies, dégradés, noir pour les textes
// ═══════════════════════════════════════════════════════════════

class AppColors {

  // ── COULEURS PRINCIPALES ─────────────────────────────────────

  // Bordeaux → identité de marque, conservé mais enrichi
  static const Color primary = Color(0xFF8B1A2E);
  static const Color primaryDark = Color(0xFF5C0F1D);
  static const Color primaryLight = Color(0xFFB5293F);

  // Bleu marial → Foi, Marie, spiritualité
  static const Color bleuMarial = Color(0xFF1565C0);
  static const Color bleuMarialLight = Color(0xFF1E88E5);

  // Or liturgique → Calices, hosties, prestige
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFF5C842);
  static const Color goldDark = Color(0xFFAA7C10);

  // Vert espérance → Vie, croissance, solidarité
  static const Color green = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFF2E7D32);

  // Violet → Avent, Carême, prière
  static const Color violet = Color(0xFF4A148C);
  static const Color violetLight = Color(0xFF6A1B9A);

  // Orange → Pentecôte, énergie, communauté
  static const Color orange = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFF57C00);

  // Rouge vif → Martyre, Esprit Saint, urgence
  static const Color red = Color(0xFFC62828);

  // ── DÉGRADÉS PRINCIPAUX ──────────────────────────────────────

  // Dégradé hero — bordeaux vers violet (header home, login)
  static const LinearGradient gradientHero = LinearGradient(
    colors: [Color(0xFF8B1A2E), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé or — pour badges premium, progression dons
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFF5C842)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé bleu marial — login hero, saint du jour
  static const LinearGradient gradientBleu = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dégradé vitrail — carrousel, cards événements
  // Inspiré directement de l'image 1 (vitrail bleu/rouge/or)
  static const LinearGradient gradientVitrail = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF8B1A2E), Color(0xFFD4A017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé vert — dons, solidarité
  static const LinearGradient gradientGreen = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé orange — podcast, événements
  static const LinearGradient gradientOrange = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── FONDS ET SURFACES ────────────────────────────────────────

  // Blanc pur — fond principal (client demande du blanc)
  static const Color background = Color(0xFFFFFFFF);

  // Gris très léger chaud — surfaces, cards
  static const Color surface = Color(0xFFF8F5F0);

  // Surface légèrement plus foncée — champs de saisie
  static const Color surfaceInput = Color(0xFFF0EDE8);

  // ── TEXTES (demande client : noir titres, gris foncé sous-titres) ──

  static const Color textTitle = Color(0xFF0A0A0A);      // Noir pur
  static const Color textSubtitle = Color(0xFF424242);   // Gris foncé
  static const Color textBody = Color(0xFF2D2D2D);        // Presque noir
  static const Color textSecondary = Color(0xFF757575);   // Gris moyen
  static const Color textOnDark = Color(0xFFFFFFFF);      // Blanc sur fonds colorés
  static const Color textOnGold = Color(0xFF3E2000);      // Brun foncé sur or

  // ── ÉTATS ────────────────────────────────────────────────────

  static const Color success = Color(0xFF1B5E20);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF1565C0);

  // ── DIVERS ───────────────────────────────────────────────────

  static const Color divider = Color(0xFFE0D9D0);
  static const Color shadow = Color(0x1A000000);

  // ── COULEURS PAR MODULE ──────────────────────────────────────
  // Chaque module a sa couleur signature — cohérence visuelle

  static const Color colorMesse = Color(0xFF8B1A2E);      // Bordeaux
  static const Color colorCasuels = Color(0xFF4A148C);    // Violet
  static const Color colorDons = Color(0xFF1B5E20);       // Vert
  static const Color colorPodcast = Color(0xFFE65100);    // Orange
  static const Color colorAnnonces = Color(0xFF1565C0);   // Bleu marial
  static const Color colorActualites = Color(0xFFD4A017); // Or
  static const Color colorSaint = Color(0xFF1565C0);      // Bleu marial
  static const Color colorTexte = Color(0xFF4A148C);      // Violet
}