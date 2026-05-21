// Section "Aujourd'hui" — 2 cards côte à côte :
// Texte du jour (icône livre) et Saint du jour (icône église).
// Chaque card affiche un aperçu du contenu.

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../features/spirituel/screens/saint_jour_screen.dart';
import '../../../features/spirituel/screens/text_jour_screen.dart';

class TodaySection extends StatelessWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Text("Aujourd'hui", style: AppTextStyles.heading2),

          const SizedBox(height: 12),

          // Les 2 cards en ligne
          Row(
            children: [
              // Card "Texte du jour"
              Expanded(
                child: _TodayCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Texte du jour',
                  // Texte d'aperçu — en prod, vient de Supabase
                  preview:
                      '"Le Seigneur est mon berger, je ne manque de rien..."',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TexteJourScreen()),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Card "Saint du jour"
              Expanded(
                child: _TodayCard(
                  icon: Icons.church_outlined,
                  title: 'Saint du jour',
                  preview: 'Saint Augustin d\'Hippone, Père de l\'Église...',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SaintJourScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card individuelle ──────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String preview;
  final VoidCallback onTap;

  const _TodayCard({
    required this.icon,
    required this.title,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône dans un cercle bordeaux clair
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),

            const SizedBox(height: 10),

            // Titre de la card
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            // Aperçu du contenu — 3 lignes max
            Text(
              preview,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}