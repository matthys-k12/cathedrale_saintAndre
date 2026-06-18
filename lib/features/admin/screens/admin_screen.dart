// Dashboard d'administration — accessible uniquement si is_admin = true dans profiles.
//
// Pour activer un admin dans Supabase :
//   ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;
//   UPDATE profiles SET is_admin = true WHERE id = '<uuid_admin>';
//
// Modules disponibles :
//   - Actualités : ajouter/modifier des articles avec photos ou vidéo
//   - Annonces : publier des annonces paroissiales
//   - Demandes : valider les messes, casuels, dons en attente
//   - Utilisateurs : consulter les paroissiens inscrits

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import 'admin_annonces_screen.dart';
import 'admin_actualites_screen.dart';
import 'admin_demandes_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Compteurs en attente chargés depuis Supabase
  int _messesEnAttente = 0;
  int _casuelsEnAttente = 0;
  int _donsEnAttente = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        supabase
            .from('messe_demandes')
            .select('id')
            .eq('statut', 'en_attente'),
        supabase
            .from('casuel_demandes')
            .select('id')
            .eq('statut', 'en_attente'),
        supabase
            .from('dons')
            .select('id')
            .eq('statut', 'en_attente'),
      ]);

      if (mounted) {
        setState(() {
          _messesEnAttente = (results[0] as List).length;
          _casuelsEnAttente = (results[1] as List).length;
          _donsEnAttente = (results[2] as List).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Résumé en attente ────────────────────
                          if (_totalEnAttente > 0) _buildAlertBanner(),

                          const SizedBox(height: 20),

                          // ── Modules de contenu ───────────────────
                          Text(
                            'CONTENU',
                            style: AppTextStyles.fieldLabel.copyWith(
                              color: AppColors.textSecondary, fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildModuleCard(
                            icon: Icons.article_outlined,
                            label: 'Actualités',
                            description: 'Publier des articles avec photos ou vidéo',
                            color: AppColors.green,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminActualitesScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildModuleCard(
                            icon: Icons.campaign_outlined,
                            label: 'Annonces',
                            description: 'Gérer les annonces paroissiales',
                            color: AppColors.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminAnnoncesScreen()),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Modules de gestion ───────────────────
                          Text(
                            'DEMANDES',
                            style: AppTextStyles.fieldLabel.copyWith(
                              color: AppColors.textSecondary, fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildModuleCard(
                            icon: Icons.mail_outline_rounded,
                            label: 'Messes',
                            description: 'Valider les demandes de messe',
                            color: AppColors.navy,
                            badge: _messesEnAttente,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminDemandesScreen(type: 'messes'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildModuleCard(
                            icon: Icons.receipt_long_outlined,
                            label: 'Casuels',
                            description: 'Valider les demandes de casuels',
                            color: AppColors.colorCasuels,
                            badge: _casuelsEnAttente,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminDemandesScreen(type: 'casuels'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildModuleCard(
                            icon: Icons.favorite_outline_rounded,
                            label: 'Dons',
                            description: 'Consulter et valider les dons',
                            color: const Color(0xFF1D9E75),
                            badge: _donsEnAttente,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminDemandesScreen(type: 'dons'),
                              ),
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

  int get _totalEnAttente =>
      _messesEnAttente + _casuelsEnAttente + _donsEnAttente;

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.navy,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADMINISTRATION',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                'Cathédrale Saint André',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadStats,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_totalEnAttente demande${_totalEnAttente > 1 ? 's' : ''} en attente de validation',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
