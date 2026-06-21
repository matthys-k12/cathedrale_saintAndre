import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_config.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class ActualiteDetailScreen extends StatefulWidget {
  // Passage direct (depuis la liste) OU chargement par ID (depuis deep link)
  final Map<String, dynamic>? actualite;
  final String? actualiteId;

  const ActualiteDetailScreen({
    super.key,
    this.actualite,
    this.actualiteId,
  }) : assert(actualite != null || actualiteId != null,
            'actualite ou actualiteId obligatoire');

  @override
  State<ActualiteDetailScreen> createState() =>
      _ActualiteDetailScreenState();
}

class _ActualiteDetailScreenState extends State<ActualiteDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.actualite != null) {
      _data = widget.actualite;
    } else {
      _loading = true;
      _loadById();
    }
  }

  Future<void> _loadById() async {
    try {
      final result = await supabase
          .from('actualites')
          .select('*, actualite_photos(*)')
          .eq('id', widget.actualiteId!)
          .single();
      if (mounted) setState(() { _data = Map<String, dynamic>.from(result); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _photos {
    final raw = _data?['actualite_photos'] as List?;
    if (raw == null || raw.isEmpty) return [];
    final sorted = [...raw]
      ..sort((a, b) =>
          (a['ordre'] as int).compareTo(b['ordre'] as int));
    return sorted.map<String>((p) => p['url'] as String).toList();
  }

  bool get _aVideo =>
      _data?['video_url'] != null &&
      (_data!['video_url'] as String).isNotEmpty;

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

  Future<void> _partager() async {
    final id    = _data!['id'] ?? '';
    final titre = _data!['titre'] ?? '';
    final categorie = _labelCategorie(_data!['categorie'] ?? '');
    final date  = _formatDateComplete(_data!['created_at']);

    final sb = StringBuffer();
    sb.writeln('📰 $titre');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('$categorie · $date');
    if (_photos.isNotEmpty) sb.writeln('📸 ${_photos.length} photo(s)');
    sb.writeln();
    sb.writeln('📲 Lire l\'article complet :');
    sb.writeln(partageActualite(id));
    sb.writeln();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📱 Cathédrale St André · Yopougon');
    sb.write('(L\'app doit être installée pour ouvrir le lien)');

    await Share.share(sb.toString(), subject: titre);
  }

  // Ouvrir la vidéo dans une webview ou navigateur externe
  Future<void> _ouvrirVideo() async {
    final videoUrl = _data!['video_url'] as String;
    await Share.share(videoUrl, subject: _data!['titre'] ?? 'Vidéo');
  }

  void _ouvrirPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photos: _photos,
          initialIndex: index,
          titre: _data!['titre'] ?? '',
        ),
      ),
    );
  }

  String _labelCategorie(String cat) {
    switch (cat) {
      case 'vie_paroisse': return 'VIE DE LA PAROISSE';
      case 'evenements':   return 'ÉVÉNEMENTS';
      case 'social':       return 'SOCIAL';
      case 'liturgie':     return 'LITURGIE';
      default:             return 'ACTUALITÉ';
    }
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
    // Chargement en cours (deep link par ID)
    if (_loading || _data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: BackButton(color: AppColors.primary),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final info = _infoCategorie(_data!['categorie'] ?? '');

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
                        child: Stack(
                          children: [
                            // Badge "voir les photos"
                            Positioned(
                              bottom: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library_outlined,
                                        color: Colors.white, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      _photos.length > 1
                                          ? '${_photos.length} photos'
                                          : 'Voir la photo',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                              info['label'] as String,
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
                                  _data!['created_at']),
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Titre principal
                        Text(
                          _data!['titre'] ?? '',
                          style: AppTextStyles.heading2.copyWith(
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          width: 40, height: 3,
                          decoration: BoxDecoration(
                            color: info['color'] as Color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Article complet par paragraphes
                        ...(_data!['article'] ?? '')
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

                  // ── Galerie photos scrollable ──────────────────
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
                          Text('Galerie photos', style: AppTextStyles.heading2),
                          const SizedBox(width: 8),
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

                    SizedBox(
                      height: 150,
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
                                  width: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                    image: DecorationImage(
                                      image: NetworkImage(_photos[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6, right: 6,
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
                                // Bouton menu (tap direct — remplace long press qui bloquait le scroll)
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () => _menuPhoto(context, _photos[i], i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                        size: 12,
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text(
                        'Appui long sur une photo pour enregistrer ou partager',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],

                  // ── Boutons partage + télécharger ──────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      children: [
                        // Partager
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _partager,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              'PARTAGER CETTE ACTUALITÉ',
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

                        // Télécharger toutes les photos (si galerie)
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () => _telechargerToutesPhotos(context),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(
                                _photos.length == 1
                                    ? 'ENREGISTRER LA PHOTO'
                                    : 'ENREGISTRER LES ${_photos.length} PHOTOS',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  // Menu contextuel photo (appui long sur thumbnail)
  void _menuPhoto(BuildContext context, String url, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Photo ${index + 1}/${_photos.length}',
                style: AppTextStyles.heading2.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.download_rounded,
                    color: AppColors.primary),
                title: const Text('Enregistrer dans la galerie'),
                onTap: () async {
                  Navigator.pop(context);
                  await _telechargerPhoto(context, url, index + 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded,
                    color: AppColors.primary),
                title: const Text('Partager cette photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _partagerUnePhoto(url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded,
                    color: AppColors.textSecondary),
                title: const Text('Voir en plein écran'),
                onTap: () {
                  Navigator.pop(context);
                  _ouvrirPhoto(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Partager une seule photo via share sheet
  Future<void> _partagerUnePhoto(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final xfile = XFile.fromData(bytes, mimeType: 'image/jpeg',
            name: 'saint_andre_photo.jpg');
        await Share.shareXFiles([xfile],
            text: '📸 ${_data!['titre'] ?? ''}\n— Cathédrale St André · Yopougon');
      }
    } catch (_) {
      // Fallback : partager le lien direct
      await Share.share(url, subject: _data!['titre'] ?? '');
    }
  }

  // Télécharger une photo en galerie
  Future<void> _telechargerPhoto(BuildContext ctx, String url, int num) async {
    _showSnack(ctx, '⬇️ Téléchargement en cours…', loading: true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await Gal.putImageBytes(
          response.bodyBytes,
          album: 'Saint André',
        );
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          _showSnack(ctx, '✓ Photo $num enregistrée dans la galerie');
        }
      }
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
        _showSnack(ctx, 'Erreur lors du téléchargement', error: true);
      }
    }
  }

  // Télécharger toutes les photos
  Future<void> _telechargerToutesPhotos(BuildContext ctx) async {
    _showSnack(ctx, '⬇️ Téléchargement de ${_photos.length} photo(s)…',
        loading: true);
    int success = 0;
    for (int i = 0; i < _photos.length; i++) {
      try {
        final response = await http.get(Uri.parse(_photos[i]));
        if (response.statusCode == 200) {
          await Gal.putImageBytes(
            response.bodyBytes,
            album: 'Saint André',
          );
          success++;
        }
      } catch (_) {}
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      _showSnack(ctx,
          success == _photos.length
              ? '✓ ${success} photo(s) enregistrée(s) dans la galerie'
              : '$success/${_photos.length} photo(s) enregistrée(s)');
    }
  }

  void _showSnack(BuildContext ctx, String msg,
      {bool loading = false, bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            if (loading) const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error
            ? AppColors.error
            : error == false && loading
                ? AppColors.textSecondary
                : const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: loading
            ? const Duration(seconds: 30)
            : const Duration(seconds: 3),
      ),
    );
  }
}

// ── Viewer photo plein écran avec swipe + actions ────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String titre;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.titre,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showActions = true;

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

  Future<void> _telecharger(BuildContext ctx) async {
    final url = widget.photos[_currentIndex];
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Téléchargement…'),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 30),
      ),
    );
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await Gal.putImageBytes(
          response.bodyBytes,
          album: 'Saint André',
        );
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('✓ Photo enregistrée dans la galerie'),
              backgroundColor: const Color(0xFF1D9E75),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors du téléchargement'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _partager() async {
    final url = widget.photos[_currentIndex];
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final xfile = XFile.fromData(response.bodyBytes,
            mimeType: 'image/jpeg', name: 'saint_andre_photo.jpg');
        await Share.shareXFiles([xfile],
            text: '📸 ${widget.titre}\n— Cathédrale St André · Yopougon');
        return;
      }
    } catch (_) {}
    await Share.share(url, subject: widget.titre);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showActions = !_showActions),
          child: Stack(
            children: [
              // Photos swipables
              PageView.builder(
                controller: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) {
                  return InteractiveViewer(
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

              // Header : fermer + titre
              AnimatedOpacity(
                opacity: _showActions ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16, right: 16, bottom: 24,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.titre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1}/${widget.photos.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer : actions (télécharger, partager) + dots
              AnimatedOpacity(
                opacity: _showActions ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      left: 24, right: 24, top: 24,
                    ),
                    child: Column(
                      children: [
                        // Dots
                        if (widget.photos.length > 1)
                          Row(
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

                        const SizedBox(height: 16),

                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: _ActionBtn(
                                icon: Icons.download_rounded,
                                label: 'Enregistrer',
                                onTap: () => _telecharger(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionBtn(
                                icon: Icons.share_rounded,
                                label: 'Partager',
                                onTap: _partager,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
