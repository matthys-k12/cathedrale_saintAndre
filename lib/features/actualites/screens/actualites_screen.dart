// Module Actualités de la Paroisse
//
// Style éditorial inspiré de la maquette :
// - Card "À la une" en grand format avec image pleine largeur
// - Filtres catégories en pills horizontales
// - Cards standard avec image + badge + titre serif + aperçu
// - Écran détail : article complet + galerie photos (max 10)
//   ou lecteur vidéo YouTube/Vimeo

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import 'actualite_detail_screen.dart';

class ActualitesScreen extends StatefulWidget {
  const ActualitesScreen({super.key});

  @override
  State<ActualitesScreen> createState() => _ActualitesScreenState();
}

class _ActualitesScreenState extends State<ActualitesScreen> {
  List<Map<String, dynamic>> _actualites = [];
  bool _isLoading = true;
  String _filtreActif = 'tout';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'tout', 'label': 'Tout'},
    {'id': 'vie_paroisse', 'label': 'Vie de la Paroisse'},
    {'id': 'evenements', 'label': 'Événements'},
    {'id': 'social', 'label': 'Social'},
    {'id': 'liturgie', 'label': 'Liturgie'},
  ];

  @override
  void initState() {
    super.initState();
    _loadActualites();
  }

  Future<void> _loadActualites() async {
    try {
      // Charger les actualités avec leurs photos
      final data = await supabase
          .from('actualites')
          .select('*, actualite_photos(url, ordre)')
          .order('est_a_la_une', ascending: false)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _actualites = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _actualitesFiltrees {
    if (_filtreActif == 'tout') return _actualites;
    return _actualites
        .where((a) => a['categorie'] == _filtreActif)
        .toList();
  }

  // Première photo d'une actualité
  String? _premierePhoto(Map<String, dynamic> actu) {
    final photos = actu['actualite_photos'] as List?;
    if (photos == null || photos.isEmpty) return null;
    final sorted = [...photos]
      ..sort((a, b) => (a['ordre'] as int).compareTo(b['ordre'] as int));
    return sorted.first['url'] as String?;
  }

  // Couleur et label par catégorie
  Map<String, dynamic> _infoCategorie(String cat) {
    switch (cat) {
      case 'vie_paroisse':
        return {'label': 'VIE DE LA PAROISSE', 'color': AppColors.primary};
      case 'evenements':
        return {'label': 'ÉVÉNEMENTS', 'color': const Color(0xFFC9922A)};
      case 'social':
        return {'label': 'SOCIAL', 'color': const Color(0xFF1D9E75)};
      case 'liturgie':
        return {'label': 'LITURGIE', 'color': const Color(0xFF185FA5)};
      default:
        return {'label': 'ACTUALITÉ', 'color': AppColors.primary};
    }
  }

  String _dateRelative(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Il y a 1 jour';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    const mois = ['jan.', 'fév.', 'mar.', 'avr.', 'mai', 'juin',
                  'juil.', 'août', 'sep.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar logo
                  Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('SA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saint André',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Cloche
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filtres catégories ────────────────────────────────
            SizedBox(
              height: 34,
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
                        horizontal: 16, vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Liste des actualités ──────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )
                  : _actualitesFiltrees.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune actualité disponible',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _actualitesFiltrees.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) {
                            final actu = _actualitesFiltrees[i];
                            // La première actualité "à la une" → grande card
                            if (actu['est_a_la_une'] == true && i == 0) {
                              return _buildUneCard(actu);
                            }
                            return _buildStandardCard(actu);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card "À la une" — grande image pleine largeur ────────────────
  Widget _buildUneCard(Map<String, dynamic> actu) {
    final photo = _premierePhoto(actu);
    final info = _infoCategorie(actu['categorie']);

    return GestureDetector(
      onTap: () => _ouvrirDetail(actu),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Image grande
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary,
              image: photo != null
                  ? DecorationImage(
                      image: NetworkImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Overlay dégradé bas
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // Badge "À LA UNE" en haut à gauche
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'À LA UNE',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),

                // Placeholder si pas d'image
                if (photo == null)
                  Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Catégorie + date
          Row(
            children: [
              Text(
                info['label'],
                style: AppTextStyles.fieldLabel.copyWith(
                  color: info['color'] as Color,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3, height: 3,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _dateRelative(actu['created_at']),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Titre en grand serif
          Text(
            actu['titre'],
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontSize: 22,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Aperçu article
          Text(
            actu['article'],
            style: AppTextStyles.bodySmall.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Card standard ────────────────────────────────────────────────
  Widget _buildStandardCard(Map<String, dynamic> actu) {
    final photo = _premierePhoto(actu);
    final info = _infoCategorie(actu['categorie']);

    return GestureDetector(
      onTap: () => _ouvrirDetail(actu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image
            if (photo != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Image.network(
                  photo,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Catégorie + date
                  Row(
                    children: [
                      Text(
                        info['label'],
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: info['color'] as Color,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _dateRelative(actu['created_at']),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Titre
                  Text(
                    actu['titre'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Aperçu
                  Text(
                    actu['article'],
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDetail(Map<String, dynamic> actu) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActualiteDetailScreen(actualite: actu),
      ),
    );
  }
}