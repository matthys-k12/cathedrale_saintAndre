// Module Podcast — liste des séries et épisodes
// Design inspiré de Prions en Église :
// - Header coloré plein (orange #E65100)
// - Cards éditoriales avec image + badge GRATUIT/PAYANT
// - Player audio intégré en bas de l'écran
// - Achat à l'épisode pour les contenus payants

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import 'poadcast_episode_screen.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({super.key});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  List<Map<String, dynamic>> _series = [];
  bool _isLoading = true;
  String _filtreActif = 'tout';

  final List<Map<String, String>> _categories = [
    {'id': 'tout', 'label': 'Tout'},
    {'id': 'enseignement', 'label': 'Enseignements'},
    {'id': 'bible', 'label': 'Bible'},
    {'id': 'temoignage', 'label': 'Témoignages'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    try {
      // Charger les séries avec leurs épisodes
      final data = await supabase
          .from('podcast_series')
          .select('*, podcast_episodes(*)')
          .eq('est_actif', true)
          .order('ordre');

      if (mounted) {
        setState(() {
          _series = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _seriesFiltrees {
    if (_filtreActif == 'tout') return _series;
    return _series
        .where((s) => s['categorie'] == _filtreActif)
        .toList();
  }

  // Épisodes vidéo de toutes les séries — pour le carousel du haut
  List<Map<String, dynamic>> get _videoEpisodes {
    final videos = <Map<String, dynamic>>[];
    for (final serie in _series) {
      final eps = serie['podcast_episodes'] as List? ?? [];
      for (final ep in eps) {
        if ((ep['format'] as String? ?? 'audio') == 'video') {
          videos.add({
            ...Map<String, dynamic>.from(ep),
            '_serie_nom': serie['titre'] as String? ?? '',
            '_serie_categorie': serie['categorie'] as String? ?? 'enseignement',
          });
        }
      }
    }
    return videos;
  }

  // Extrait l'ID YouTube d'une URL pour construire la miniature
  static String? _thumbUrl(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(mediaUrl);
      String? id;
      if (uri.host == 'youtu.be' || uri.host == 'www.youtu.be') {
        id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.host.contains('youtube.com')) {
        id = uri.queryParameters['v'];
        if (id == null && uri.pathSegments.length > 1 && uri.pathSegments.first == 'embed') {
          id = uri.pathSegments[1];
        }
      }
      if (id != null && id.isNotEmpty) {
        return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
      }
    } catch (_) {}
    return null;
  }

  // Nombre d'épisodes d'une série
  int _nbEpisodes(Map<String, dynamic> serie) {
    final eps = serie['podcast_episodes'] as List?;
    return eps?.length ?? 0;
  }

  // Premier épisode d'une série (pour la preview)
  Map<String, dynamic>? _premierEpisode(Map<String, dynamic> serie) {
    final eps = serie['podcast_episodes'] as List?;
    if (eps == null || eps.isEmpty) return null;
    final sorted = [...eps]..sort((a, b) =>
        (a['numero_episode'] as int).compareTo(b['numero_episode'] as int));
    return Map<String, dynamic>.from(sorted.first);
  }

  // Formater la durée en "23 min" ou "1h 12min"
  String _formatDuree(int? secondes) {
    if (secondes == null) return '';
    final min = secondes ~/ 60;
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h ${m}min';
  }

  // Couleur par catégorie
  Color _couleurCategorie(String cat) {
    switch (cat) {
      case 'enseignement': return AppColors.orange;
      case 'bible': return AppColors.bleuMarial;
      case 'temoignage': return AppColors.green;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header orange plein — couleur signature Podcast ───
            Container(
              color: AppColors.orange,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Text('Retour', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Podcasts',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enseignements & Témoignages',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Aperçus vidéos (si présents) ──────────────────────
            if (!_isLoading && _videoEpisodes.isNotEmpty)
              _buildVideoCarousel(),

            // ── Filtres catégories ─────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 6,
                ),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = _filtreActif == cat['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filtreActif = cat['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // Pill noire si active, grise si inactive
                        // Style exactement comme Prions en Église
                        color: isActive
                            ? const Color(0xFF0A0A0A)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0A0A0A)
                              : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        cat['label']!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSubtitle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Liste des séries ──────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orange,
                      ),
                    )
                  : _seriesFiltrees.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun podcast disponible',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _seriesFiltrees.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) {
                            return _buildSerieCard(_seriesFiltrees[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carousel vidéos en haut de l'écran ───────────────────────────
  Widget _buildVideoCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Vidéos',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textTitle,
            ),
          ),
        ),
        SizedBox(
          height: 144,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _videoEpisodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _buildVideoThumbCard(_videoEpisodes[i]),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
      ],
    );
  }

  Widget _buildVideoThumbCard(Map<String, dynamic> ep) {
    final thumbUrl = _thumbUrl(ep['url_media'] as String?);
    final serieNom = ep['_serie_nom'] as String? ?? '';
    final titre = ep['titre'] as String? ?? '';
    final couleur = _couleurCategorie(ep['_serie_categorie'] as String? ?? 'enseignement');

    return GestureDetector(
      onTap: () {
        final cleanEp = Map<String, dynamic>.from(ep)
          ..remove('_serie_nom')
          ..remove('_serie_categorie');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PodcastEpisodeScreen(
              episode: cleanEp,
              serieNom: serieNom,
            ),
          ),
        );
      },
      child: Container(
        width: 185,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: couleur.withValues(alpha: 0.15),
                            child: Icon(Icons.videocam_outlined, color: couleur, size: 32),
                          ),
                        )
                      : Container(
                          color: couleur.withValues(alpha: 0.15),
                          child: Icon(Icons.videocam_outlined, color: couleur, size: 32),
                        ),
                  // Overlay play
                  Center(
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.orange,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Text(
                titre,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card d'une série ──────────────────────────────────────────────
  Widget _buildSerieCard(Map<String, dynamic> serie) {
    final couleur = _couleurCategorie(serie['categorie'] ?? 'enseignement');
    final nbEps = _nbEpisodes(serie);
    final premierEp = _premierEpisode(serie);
    final episodes = List<Map<String, dynamic>>.from(
      serie['podcast_episodes'] as List? ?? [],
    )..sort((a, b) =>
        (a['numero_episode'] as int).compareTo(b['numero_episode'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Grande card série ──────────────────────────────────
        GestureDetector(
          onTap: () {
            if (premierEp != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PodcastEpisodeScreen(
                    episode: premierEp,
                    serieNom: serie['titre'],
                  ),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Image de la série
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        color: couleur.withValues(alpha:0.15),
                      ),
                      child: serie['image_url'] != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                              child: Image.network(
                                serie['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildImagePlaceholder(couleur, serie),
                              ),
                            )
                          : _buildImagePlaceholder(couleur, serie),
                    ),

                    // Badge catégorie en haut à gauche
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: couleur,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (serie['categorie'] as String)
                              .toUpperCase()
                              .replaceAll('_', ' '),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Nombre d'épisodes en haut à droite
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$nbEps épisode${nbEps > 1 ? 's' : ''}',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Infos de la série
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre de la série
                      Text(
                        serie['titre'],
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTitle,
                        ),
                      ),

                      if (serie['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          serie['description'],
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSubtitle,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Liste des épisodes de la série ─────────────────────
        const SizedBox(height: 10),
        ...episodes.map((ep) => _buildEpisodeRow(ep, serie, couleur)),
      ],
    );
  }

  // Placeholder image avec icône
  Widget _buildImagePlaceholder(Color couleur, Map<String, dynamic> serie) {
    return Container(
      decoration: BoxDecoration(
        color: couleur.withValues(alpha:0.12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.podcasts_rounded, color: couleur, size: 48),
            const SizedBox(height: 8),
            Text(
              serie['titre'],
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Row d'un épisode ──────────────────────────────────────────────
  Widget _buildEpisodeRow(
    Map<String, dynamic> ep,
    Map<String, dynamic> serie,
    Color couleur,
  ) {
    final isGratuit = ep['est_gratuit'] as bool? ?? true;
    final format = ep['format'] as String? ?? 'audio';
    final duree = _formatDuree(ep['duree_secondes'] as int?);
    final prix = ep['prix'] as int? ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PodcastEpisodeScreen(
              episode: Map<String, dynamic>.from(ep),
              serieNom: serie['titre'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [

            // Numéro d'épisode dans un cercle coloré
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isGratuit
                    ? couleur.withValues(alpha:0.12)
                    : const Color(0xFF0A0A0A).withValues(alpha:0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  format == 'audio'
                      ? Icons.headphones_rounded
                      : Icons.play_circle_outline_rounded,
                  color: isGratuit ? couleur : AppColors.textSubtitle,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Infos épisode
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numéro + titre
                  Text(
                    'Ép. ${ep['numero_episode']} — ${ep['titre']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTitle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Format + durée
                  Row(
                    children: [
                      // Badge format
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          format == 'audio' ? 'AUDIO' : 'VIDÉO',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: couleur,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      if (duree.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          duree,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Badge GRATUIT ou prix
            if (isGratuit)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha:0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'GRATUIT',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                    letterSpacing: 0.3,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$prix F',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}