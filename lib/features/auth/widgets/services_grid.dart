// Grille 2×2 des services principaux.
// Reproduit exactement la maquette : icône + label sous chaque service.
// Chaque bouton navigue vers le module correspondant.

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../features/messe/screens/messe_bottom_sheet.dart';
import '../../casuels/screens/casuels_screen.dart';
import '../../dons/screens/dons_screnn.dart';
// Modèle de données pour un service
class _ServiceItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Les 4 services — dans l'ordre de la maquette (gauche→droite, haut→bas)
    final services = [
      _ServiceItem(
        icon: Icons.mail_outline_rounded,
        label: 'DEMANDE DE MESSE',
        onTap:  () => showMesseBottomSheet(context),
      ),
      _ServiceItem(
        icon: Icons.receipt_long_outlined,
        label: 'CASUELS',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CasuelsScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.favorite_outline_rounded,
        label: 'DONS & DENIER DU CULTE',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonsScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.podcasts_rounded,
        label: 'PODCAST',
        onTap: () {
          // TODO : naviguer vers Podcasts
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services', style: AppTextStyles.heading2),

          const SizedBox(height: 12),

          // GridView avec 2 colonnes fixes
          GridView.count(
            crossAxisCount: 2,        // 2 colonnes
            crossAxisSpacing: 12,     // Espace horizontal entre cards
            mainAxisSpacing: 12,      // Espace vertical entre cards
            childAspectRatio: 1.6,    // Largeur / Hauteur de chaque cell
            // IMPORTANT : shrinkWrap + NeverScrollableScrollPhysics
            // car ce GridView est DANS un ScrollView parent.
            // Sans ça, Flutter se plaint de scrolls imbriqués.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: services.map((service) {
              return _ServiceCard(service: service);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Card individuelle d'un service ────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final _ServiceItem service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône dans un container bordeaux léger
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service.icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            // Label en petites majuscules — comme dans la maquette
            Text(
              service.label,
              style: AppTextStyles.fieldLabel.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}