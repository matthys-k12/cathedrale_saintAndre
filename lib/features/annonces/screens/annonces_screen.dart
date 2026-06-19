// Écran Annonces — version améliorée :
// - Header sobre avec titre + bouton cloche
// - Filtres par catégorie en pills horizontales scrollables
// - Cards d'annonces avec badge catégorie coloré,
//   indicateur "URGENT" si applicable, date relative,
//   et image optionnelle
// - Écran détail complet au tap
// - Design sobre mais nettement plus riche que la maquette initiale

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../notifications/screens/notifications_screen.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  List<Map<String, dynamic>> _annonces = [];
  bool _isLoading = true;
  String _filtreActif = 'tout'; // filtre catégorie

  // Données de démonstration — affichées quand Supabase ne retourne rien
  static const List<Map<String, dynamic>> _mockAnnonces = [
    {
      'titre': 'Retraite spirituelle de carême',
      'contenu': 'La paroisse vous invite à une retraite spirituelle durant le temps de carême. Un temps de ressourcement pour tous les paroissiens qui souhaitent approfondir leur foi et s\'ouvrir à la grâce de Dieu.',
      'categorie': 'activites',
      'est_urgent': false,
      'created_at': '2026-05-24T09:00:00',
    },
    {
      'titre': 'Publication des bans de mariage',
      'contenu': 'Nous informons la communauté paroissiale de la publication des bans de mariage de M. Jean-Claude Koné et Mme Awa Ouattara, prévue le samedi 13 juin 2026 à 10h30.',
      'categorie': 'mariage',
      'est_urgent': false,
      'created_at': '2026-05-22T14:30:00',
    },
    {
      'titre': 'Collecte urgente pour les sinistrés',
      'contenu': 'Suite aux inondations récentes dans le quartier, la paroisse organise une collecte d\'urgence pour venir en aide aux familles sinistrées. Vos dons matériels et financiers sont attendus à l\'accueil.',
      'categorie': 'associations',
      'est_urgent': true,
      'created_at': '2026-05-21T08:00:00',
    },
    {
      'titre': 'Groupe de prière "Cœur à Cœur"',
      'contenu': 'Le groupe de prière se réunit chaque jeudi à 18h30 dans la salle Saint Augustin. Nouveaux membres bienvenus. Thème du mois : "La Miséricorde divine".',
      'categorie': 'prieres',
      'est_urgent': false,
      'created_at': '2026-05-19T10:00:00',
    },
    {
      'titre': 'Assemblée générale CEB Yopougon-Gare',
      'contenu': 'Les membres de la Communauté Ecclésiale de Base (CEB) Yopougon-Gare sont convoqués en assemblée générale le dimanche 01 juin après la messe de 10h00.',
      'categorie': 'ceb',
      'est_urgent': false,
      'created_at': '2026-05-17T16:00:00',
    },
    {
      'titre': 'Rappel à Dieu — Sr Marie-Céleste ABOBO',
      'contenu': 'La famille ABOBO et la communauté paroissiale ont la douleur de faire part du rappel à Dieu de Sœur Marie-Céleste ABOBO, le dimanche 18 mai 2026. Les obsèques auront lieu à l\'église.',
      'categorie': 'rappel_a_dieu',
      'est_urgent': false,
      'created_at': '2026-05-18T12:00:00',
    },
  ];

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

  // Données effectives : Supabase si disponible, sinon mock de démonstration
  List<Map<String, dynamic>> get _annoncesEffectives =>
      _annonces.isEmpty ? _mockAnnonces : _annonces;

  // Filtrer les annonces selon la catégorie active
  List<Map<String, dynamic>> get _annoncesFiltrees {
    if (_filtreActif == 'tout') return _annoncesEffectives;
    return _annoncesEffectives
        .where((a) => a['categorie'] == _filtreActif)
        .toList();
  }

  // Couleur d'une catégorie
  Color _couleurCategorie(String categorie) {
    switch (categorie) {
      case 'activites': return const Color(0xFF7B1E3A);
      case 'mariage': return const Color(0xFFC9922A);
      case 'prieres': return const Color(0xFF1D9E75);
      case 'ceb': return const Color(0xFF185FA5);
      case 'associations': return const Color(0xFF6B3FA0);
      case 'rappel_a_dieu': return const Color(0xFF555555);
      default: return AppColors.primary;
    }
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
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header rouge avec vague en bas ────────────────────
            ClipPath(
              clipper: _AnnoncesHeaderClipper(),
              child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 42),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annonces',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Paroisse Saint André',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha:0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),

            const SizedBox(height: 4),

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
                        // Actif = fond noir encre / Inactif = blanc
                        color: isActive ? AppColors.ink : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppColors.ink : AppColors.hairlineStrong,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        cat['label'],
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.ink,
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
              color: Colors.black.withValues(alpha:0.04),
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

              // ── Ligne du haut : badge solide + date ───────────
              Row(
                children: [
                  // Badge solide — fond couleur, texte blanc, 4px radius
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: couleur,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      annonce['categorie'].toString().toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
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
                        color: AppColors.error.withValues(alpha:0.1),
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

              // ── Titre Playfair 18px w700 ──────────────────────
              Text(
                annonce['titre'],
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 6),

              // ── Aperçu contenu DM Sans 13px ───────────────────
              Text(
                annonce['contenu'],
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textBody,
                  height: 1.45,
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

  Future<void> _partagerWhatsApp() async {
    final titre = annonce['titre'] ?? '';
    final contenu = annonce['contenu'] ?? '';
    final urgent = annonce['est_urgent'] == true ? '🚨 URGENT\n\n' : '';

    final sb = StringBuffer();
    sb.writeln('📢 $titre');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln();
    sb.write(urgent);
    sb.writeln(contenu);
    sb.writeln();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📱 Annonce de la Cathédrale St André · Yopougon');

    await Share.share(sb.toString(), subject: titre);
  }

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
                    // Bouton retour + partage WhatsApp
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 20, color: couleur),
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
                        const Spacer(),
                        GestureDetector(
                          onTap: _partagerWhatsApp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.share_rounded, size: 15, color: Color(0xFF25D366)),
                                const SizedBox(width: 5),
                                Text(
                                  'WhatsApp',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF25D366),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                            color: couleur.withValues(alpha:0.1),
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

// ── Clipper vague douce pour le bas du header rouge ──────────────────
class _AnnoncesHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const curveHeight = 22.0;
    return Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        size.width / 2, size.height,
        size.width, size.height - curveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}