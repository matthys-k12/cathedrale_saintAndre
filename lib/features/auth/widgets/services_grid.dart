// Grille 2×2 des services principaux — style éditorial.
// Cards blanches avec boîte d'icône colorée solide (pas de dégradé).

import 'package:cathedrale_saint_andre/features/poadcast/screens/poadcast_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../features/messe/screens/messe_bottom_sheet.dart';
import '../../casuels/screens/casuels_screen.dart';
import '../../dons/screens/dons_screnn.dart';

// Modèle de données pour un service
class _ServiceItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.mail_outline_rounded,
        label: 'Demande de messe',
        subtitle: 'Intention · offrande',
        color: AppColors.colorMesse,
        onTap: () => showMesseBottomSheet(context),
      ),
      _ServiceItem(
        icon: Icons.receipt_long_outlined,
        label: 'Casuels',
        subtitle: 'Baptême · mariage',
        color: AppColors.colorCasuels,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CasuelsScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.favorite_outline_rounded,
        label: 'Dons et denier du culte',
        subtitle: 'Soutenir la paroisse',
        color: AppColors.colorDons,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonsScreen()),
        ),
      ),
      _ServiceItem(
        icon: Icons.podcasts_rounded,
        label: 'Podcast',
        subtitle: 'Homélies · catéchèse',
        color: AppColors.colorPodcast,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PodcastScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
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

// ── Card individuelle d'un service — fond blanc, boîte d'icône colorée ──
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boîte d'icône carrée couleur solide
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: service.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(service.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            // Titre Playfair 16px w700 letterSpacing -0.2
            Text(
              service.label,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.2,
                height: 1.2,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            // Sous-titre DM Sans 12px muted
            Text(
              service.subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
