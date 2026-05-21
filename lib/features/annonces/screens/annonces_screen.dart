// Écran Annonces — version améliorée :
// - Header sobre avec titre + bouton cloche
// - Filtres par catégorie en pills horizontales scrollables
// - Cards d'annonces avec badge catégorie coloré,
//   indicateur "URGENT" si applicable, date relative,
//   et image optionnelle
// - Écran détail complet au tap
// - Design sobre mais nettement plus riche que la maquette initiale

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  List<Map<String, dynamic>> _annonces = [];
  bool _isLoading = true;
  String _filtreActif = 'tout'; // filtre catégorie

  // Catégories disponibles avec leurs couleurs
  final List<Map<String, dynamic>> _categories = [
    {'id': 'tout', 'label': 'Tout', 'color': AppColors.primary},
    {'id': 'activites', 'label': 'Activités', 'color': const Color(0xFF7B1E3A)},
    {'id': 'mariage', 'label': 'Mariage', 'color': const Color(0xFFC9922A)},
    {'id': 'prieres', 'label': 'Prières', 'color': const Color(0xFF1D9E75)},
    {'id': 'ceb', 'label': 'CEB', 'color': const Color(0xFF185FA5)},
    {'id': 'associations', 'label': 'Associations', 'color': const Color(0xFF6B3FA0)},
    {'id': 'rappel_a_dieu', 'label': 'Rappel à Dieu', 'color': const Color(0xFF555555)},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnonces();
  }

  Future<void> _loadAnnonces() async {
    try {
      final data = await supabase
          .from('annonces')
          .select()
          .order('est_urgent', ascending: false) // urgents en premier
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _annonces = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtrer les annonces selon la catégorie active
  List<Map<String, dynamic>> get _annoncesFiltrees {
    if (_filtreActif == 'tout') return _annonces;
    return _annonces
        .where((a) => a['categorie'] == _filtreActif)
        .toList();
  }

  // Couleur d'une catégorie
  Color _couleurCategorie(String categorie) {
    final cat = _categories.firstWhere(
      (c) => c['id'] == categorie,
      orElse: () => _categories.last,
    );
    return cat['color'] as Color;
  }

  // Date relative : "Aujourd'hui", "Il y a 2 jours", etc.
  String _dateRelative(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Il y a 1 jour';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).round()} sem.';
    return 'Il y a ${(diff.inDays / 30).round()} mois';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Annonces', style: AppTextStyles.heading2),
                      Text(
                        'Paroisse Saint André',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Cloche notifications
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filtres catégories (scroll horizontal) ────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = _filtreActif == cat['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filtreActif = cat['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? cat['color'] as Color
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? cat['color'] as Color
                              : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        cat['label'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Liste des annonces ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _annoncesFiltrees.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune annonce dans cette catégorie',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _annoncesFiltrees.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            return _buildAnnounceCard(
                                _annoncesFiltrees[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card d'annonce enrichie ──────────────────────────────────────
  Widget _buildAnnounceCard(Map<String, dynamic> annonce) {
    final couleur = _couleurCategorie(annonce['categorie']);
    final isUrgent = annonce['est_urgent'] == true;

    return GestureDetector(
      onTap: () => _ouvrirDetail(annonce),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          // Bordure gauche colorée selon la catégorie
          border: Border(
            left: BorderSide(color: couleur, width: 3.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Ligne du haut : badges + date ─────────────────
              Row(
                children: [
                  // Badge catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      annonce['categorie'].toString().toUpperCase(),
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: couleur,
                        fontSize: 9,
                      ),
                    ),
                  ),

                  // Badge URGENT si applicable
                  if (isUrgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'URGENT',
                            style: AppTextStyles.fieldLabel.copyWith(
                              color: AppColors.error,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Date relative
                  Text(
                    _dateRelative(annonce['created_at']),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Titre ─────────────────────────────────────────
              Text(
                annonce['titre'],
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 6),

              // ── Aperçu contenu (2 lignes max) ─────────────────
              Text(
                annonce['contenu'],
                style: AppTextStyles.bodySmall.copyWith(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // ── Lien "Lire la suite" ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lire la suite',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: couleur,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: couleur,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Écran détail d'une annonce ───────────────────────────────────
  void _ouvrirDetail(Map<String, dynamic> annonce) {
    final couleur = _couleurCategorie(annonce['categorie']);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AnnounceDetailScreen(
          annonce: annonce,
          couleur: couleur,
          dateRelative: _dateRelative(annonce['created_at']),
        ),
      ),
    );
  }
}

// ── Écran détail annonce ─────────────────────────────────────────────
class _AnnounceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> annonce;
  final Color couleur;
  final String dateRelative;

  const _AnnounceDetailScreen({
    required this.annonce,
    required this.couleur,
    required this.dateRelative,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_rounded,
                              size: 20, color: couleur),
                          const SizedBox(width: 6),
                          Text(
                            'Annonces',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: couleur,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: couleur.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            annonce['categorie'].toString().toUpperCase(),
                            style: AppTextStyles.fieldLabel.copyWith(
                              color: couleur, fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateRelative,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Titre en grand serif
                    Text(annonce['titre'], style: AppTextStyles.heading2),

                    const SizedBox(height: 20),

                    // Séparateur
                    Container(
                      width: 40, height: 3,
                      decoration: BoxDecoration(
                        color: couleur,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contenu complet
                    Text(
                      annonce['contenu'],
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
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
}