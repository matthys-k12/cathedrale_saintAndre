// Card "Intention de prière" — fond doré/ambre avec citation en italique
// et bouton + bordeaux pour ajouter sa propre intention.
// Reproduit exactement le bas de la home dans la maquette.

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';

class IntentionCard extends StatelessWidget {
  const IntentionCard({super.key});

  // Citations qui tournent — en prod, gérées depuis Supabase
  // ou changées quotidiennement en local
  static const String _citation =
      '"Seigneur, accorde-nous la paix et la force de témoigner de ton amour en Côte d\'Ivoire."';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // Fond ambre très clair — comme dans la maquette
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label "INTENTION DE PRIÈRE" en petites majuscules or
            Row(
              children: [
                // Petite icône crayon/prière
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'INTENTION DE PRIÈRE',
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Citation en italique
            Text(
              _citation,
              style: AppTextStyles.quote.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 16),

            // Ligne du bas : texte + bouton +
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajouter mon intention',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Bouton + bordeaux rond
                GestureDetector(
                  onTap: () {
                    // TODO : ouvrir un dialog pour saisir une intention
                    _showIntentionDialog(context);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dialog simple pour saisir une intention personnelle
  void _showIntentionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Mon intention de prière',
          style: AppTextStyles.heading2,
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Écrivez votre intention...',
            hintStyle: AppTextStyles.inputHint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO : sauvegarder l'intention dans Supabase
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text('Envoyer', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}