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
import '../../../cores/utils/text_utils.dart';
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
  String _recherche = '';
  bool _searchVisible = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Données de démonstration — affichées quand Supabase ne retourne rien
  static const List<Map<String, dynamic>> _mockActualites = [
    {
      'id': 'mock_1',
      'titre': 'La Cathédrale Saint André accueille le Jubilé diocésain',
      'article': 'En ce temps fort de l\'année liturgique, la paroisse Saint André de Yopougon a eu l\'honneur d\'accueillir le jubilé diocésain. Plusieurs centaines de fidèles ont participé à cette célébration mémorable, présidée par Son Excellence l\'Archevêque du diocèse d\'Abidjan. Un moment de grâce et de communion pour toute la communauté.',
      'categorie': 'vie_paroisse',
      'est_a_la_une': true,
      'created_at': '2026-05-24T10:00:00',
      'video_url': null,
      'actualite_photos': [],
    },
    {
      'id': 'mock_2',
      'titre': 'Remise de kits à 50 familles démunies',
      'article': 'Dans le cadre de son action caritative, la paroisse Saint André a remis des kits alimentaires et scolaires à 50 familles défavorisées du quartier Yopougon. Une initiative saluée par toute la communauté et coordonnée par l\'équipe du Secours Catholique paroissial.',
      'categorie': 'social',
      'est_a_la_une': false,
      'created_at': '2026-05-20T09:00:00',
      'video_url': null,
      'actualite_photos': [],
    },
    {
      'id': 'mock_3',
      'titre': 'Inauguration de la nouvelle salle de catéchèse',
      'article': 'Après plusieurs mois de travaux, la nouvelle salle de catéchèse a été inaugurée par le curé de la paroisse. Cet espace moderne pourra accueillir jusqu\'à 80 enfants pour les cours de préparation aux sacrements. Une belle avancée pour la formation des jeunes paroissiens.',
      'categorie': 'vie_paroisse',
      'est_a_la_une': false,
      'created_at': '2026-05-15T14:00:00',
      'video_url': null,
      'actualite_photos': [],
    },
    {
      'id': 'mock_4',
      'titre': 'Concert de louanges — Dimanche 8 juin',
      'article': 'La chorale paroissiale "Voix de Lumière" organise un grand concert de louanges le dimanche 8 juin après la messe de 10h00. Tous les paroissiens et leurs familles sont chaleureusement invités à partager ce moment de prière et de joie.',
      'categorie': 'evenements',
      'est_a_la_une': false,
      'created_at': '2026-05-10T11:00:00',
      'video_url': null,
      'actualite_photos': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadActualites();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          _actualites = List<Map<String, dynamic>>.from(data).map((a) {
            return {
              ...a,
              'titre': nfc(a['titre']?.toString()),
              'article': nfc(a['article']?.toString()),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Données effectives : Supabase si disponible, sinon mock de démonstration
  List<Map<String, dynamic>> get _actualitesEffectives =>
      _actualites.isEmpty ? _mockActualites : _actualites;

  Map<String, dynamic> _normalise(Map<String, dynamic> a) => {
    ...a,
    'titre': nfc(a['titre']?.toString()),
    'article': nfc(a['article']?.toString()),
  };

  List<Map<String, dynamic>> get _actualitesFiltrees {
    final base = _actualitesEffectives.map(_normalise).toList();
    if (_recherche.trim().isEmpty) return base;
    final q = _recherche.trim().toLowerCase();
    return base.where((a) {
      final titre = (a['titre'] ?? '').toString().toLowerCase();
      final article = (a['article'] ?? '').toString().toLowerCase();
      return titre.contains(q) || article.contains(q);
    }).toList();
  }

  // Première photo d'une actualité — priorité à image_couverture
  String? _premierePhoto(Map<String, dynamic> actu) {
    final couverture = actu['image_couverture'] as String?;
    if (couverture != null && couverture.isNotEmpty) return couverture;
    final photos = actu['actualite_photos'] as List?;
    if (photos == null || photos.isEmpty) return null;
    final sorted = [...photos]
      ..sort((a, b) => (a['ordre'] as int? ?? 0).compareTo(b['ordre'] as int? ?? 0));
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

            // ── Header bloc vert solide — style éditorial ────────
            Container(
              color: AppColors.green,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Croix dans cercle blanc (38×38)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.church_rounded,
                      color: AppColors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kicker + titre
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAINT ANDRÉ',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Actualités',
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _searchVisible = !_searchVisible;
                      if (!_searchVisible) {
                        _searchCtrl.clear();
                        _recherche = '';
                      }
                    }),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _searchVisible
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                        color: _searchVisible ? AppColors.green : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche — apparaît quand loupe cliquée
            if (_searchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _recherche = v),
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une actualité...',
                    hintStyle: AppTextStyles.inputHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

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