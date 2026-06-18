import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class IntentionCard extends StatelessWidget {
  const IntentionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INTENTION DE PRIÈRE',
              style: GoogleFonts.dmSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Confiez-nous votre intention.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'La communauté la portera dans la prière cette semaine.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showIntentionDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouter une intention',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntentionDialog(BuildContext context) {
    final controller = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Mon intention de prière', style: AppTextStyles.heading2),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final texte = controller.text.trim();
                      if (texte.isEmpty) return;
                      setSt(() => sending = true);
                      try {
                        final userId = supabase.auth.currentUser?.id;
                        await supabase.from('intentions_priere').insert({
                          'texte': texte,
                          'user_id': userId,
                          'est_lue': false,
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Intention envoyée. Merci !',
                                style: GoogleFonts.dmSans(color: Colors.white),
                              ),
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (_) {
                        setSt(() => sending = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erreur lors de l\'envoi. Réessayez.',
                                style: GoogleFonts.dmSans(color: Colors.white),
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Envoyer', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}
