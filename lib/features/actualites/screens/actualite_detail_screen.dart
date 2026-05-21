// Écran détail d'une actualité :
// - Titre + article complet
// - Galerie photos scrollable horizontalement (max 10)
//   avec viewer plein écran au tap
// - OU vidéo YouTube/Vimeo si video_url renseigné
// - Bouton partage WhatsApp

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';

class ActualiteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> actualite;

  const ActualiteDetailScreen({super.key, required this.actualite});

  @override
  State<ActualiteDetailScreen> createState() =>
      _ActualiteDetailScreenState();
}

class _ActualiteDetailScreenState extends State<ActualiteDetailScreen> {
  // Photos triées par ordre
  List<String> get _photos {
    final raw = widget.actualite['actualite_photos'] as List?;
    if (raw == null || raw.isEmpty) return [];
    final sorted = [...raw]
      ..sort((a, b) =>
          (a['ordre'] as int).compareTo(b['ordre'] as int));
    return sorted.map<String>((p) => p['url'] as String).toList();
  }

  bool get _aVideo =>
      widget.actualite['video_url'] != null &&
      (widget.actualite['video_url'] as String).isNotEmpty;

  String _formatDateComplete(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi',
                   'Vendredi', 'Samedi', 'Dimanche'];
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  Future<void> _partagerWhatsApp() async {
    final texte = Uri.encodeComponent(
      '📰 ${widget.actualite['titre']}\n\n'
      '${widget.actualite['article'].toString().substring(0, 
        widget.actualite['article'].toString().length > 200 ? 200 : 
        widget.actualite['article'].toString().length)}...\n\n'
      'Application Saint André Yopougon',
    );
    final url = Uri.parse('https://wa.me/?text=$texte');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Ouvrir la vidéo YouTube/Vimeo dans le navigateur
  Future<void> _ouvrirVideo() async {
    final url = Uri.parse(widget.actualite['video_url']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Ouvrir une photo en plein écran
  void _ouvrirPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(photos: _photos, initialIndex: index),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final info = _infoCategorie(widget.actualite['categorie']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Bouton retour ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Actualités',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Image hero (première photo) ────────────────
                  if (_photos.isNotEmpty && !_aVideo)
                    GestureDetector(
                      onTap: () => _ouvrirPhoto(0),
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.surface,
                          image: DecorationImage(
                            image: NetworkImage(_photos.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // ── Thumbnail vidéo ────────────────────────────
                  if (_aVideo)
                    GestureDetector(
                      onTap: _ouvrirVideo,
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.primary,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Icône play
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.primary,
                                size: 38,
                              ),
                            ),
                            // Label
                            Positioned(
                              bottom: 16,
                              child: Text(
                                'REGARDER LA VIDÉO',
                                style: AppTextStyles.fieldLabel.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              _formatDateComplete(
                                  widget.actualite['created_at']),
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Titre principal
                        Text(
                          widget.actualite['titre'],
                          style: AppTextStyles.heading2.copyWith(
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Séparateur décoratif
                        Container(
                          width: 40, height: 3,
                          decoration: BoxDecoration(
                            color: info['color'] as Color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Article complet par paragraphes
                        ...widget.actualite['article']
                            .toString()
                            .split('\n\n')
                            .map<Widget>((para) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              para.trim(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                height: 1.8,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  // ── Galerie photos (si plusieurs photos) ──────
                  if (_photos.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 0, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4, height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Galerie photos',
                              style: AppTextStyles.heading2),
                          const SizedBox(width: 8),
                          // Compteur photos
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_photos.length} photos',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scroll horizontal de photos
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          return GestureDetector(
                            onTap: () => _ouvrirPhoto(i),
                            child: Stack(
                              children: [
                                Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                    image: DecorationImage(
                                      image: NetworkImage(_photos[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Numéro de la photo
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${i + 1}/${_photos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],

                  // ── Bouton partage ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _partagerWhatsApp,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(
                          'PARTAGER SUR WHATSAPP',
                          style: AppTextStyles.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Viewer photo plein écran avec swipe ──────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photos swipables
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                // Permet de zoomer sur la photo
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.photos[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Bouton fermer
          Positioned(
            top: 48, right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Compteur photos en bas
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}