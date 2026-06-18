// Écran lecteur d'un épisode podcast
// - Audio : player avec boutons play/pause/avance/recul
//   et barre de progression
// - Vidéo : bouton pour ouvrir YouTube/lien externe
// - Si payant : vérifier si déjà acheté, sinon afficher
//   le BottomSheet de paiement

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../widgets/audio_player_widget.dart';

class PodcastEpisodeScreen extends StatefulWidget {
  final Map<String, dynamic> episode;
  final String serieNom;

  const PodcastEpisodeScreen({
    super.key,
    required this.episode,
    required this.serieNom,
  });

  @override
  State<PodcastEpisodeScreen> createState() => _PodcastEpisodeScreenState();
}

class _PodcastEpisodeScreenState extends State<PodcastEpisodeScreen> {
  bool _isLoading = true;
  bool _aAcces = false; // true si gratuit ou déjà acheté
  bool _isPaying = false;
  String _operateur = 'wave';
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave', 'label': 'Wave', 'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange Money', 'color': const Color(0xFFFF6600)},
    {'id': 'mtn', 'label': 'MTN MoMo', 'color': const Color(0xFFFFCC00)},
    {'id': 'moov', 'label': 'Moov Money', 'color': const Color(0xFF0066CC)},
  ];

  @override
  void initState() {
    super.initState();
    _verifierAcces();
    _initVideoController();
  }

  void _initVideoController() {
    final format = widget.episode['format'] as String? ?? 'audio';
    if (format != 'video') return;
    final url = widget.episode['url_media'] as String? ?? '';
    if (url.isEmpty) return;

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      // Vidéo YouTube
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    } else {
      // Vidéo directe (Supabase storage, MP4, etc.)
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: false,
              looping: false,
              allowFullScreen: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: AppColors.orange,
                handleColor: AppColors.orangeLight,
                bufferedColor: AppColors.orangeSoft,
                backgroundColor: AppColors.divider,
              ),
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _verifierAcces() async {
    final isGratuit = widget.episode['est_gratuit'] as bool? ?? true;

    if (isGratuit) {
      // Accès direct
      setState(() {
        _aAcces = true;
        _isLoading = false;
      });
      return;
    }

    // Vérifier si l'utilisateur a déjà acheté cet épisode
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final achat = await supabase
          .from('podcast_achats')
          .select('id')
          .eq('user_id', userId)
          .eq('episode_id', widget.episode['id'])
          .eq('statut', 'valide')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _aAcces = achat != null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acheterEpisode() async {
    setState(() => _isPaying = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non connecté');

      final prix = widget.episode['prix'] as int? ?? 0;
      final fraisMobileMoney = (prix * 0.01).round();

      await supabase.from('podcast_achats').insert({
        'user_id': userId,
        'episode_id': widget.episode['id'],
        'montant': prix,
        'frais_plateforme': 200,
        'frais_mobile_money': fraisMobileMoney,
        'operateur_paiement': _operateur,
        'statut': 'valide',
      });

      if (mounted) {
        Navigator.of(context).pop(); // Fermer le sheet de paiement
        setState(() => _aAcces = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Achat réussi ! Bonne écoute 🎧'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  // Ouvrir la vidéo dans le navigateur
  Future<void> _ouvrirVideo() async {
    final url = Uri.parse(widget.episode['url_media']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _ouvrirPaiement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _buildPaiementSheet(),
    );
  }

  // Formater la durée
  String _formatDuree(int? secondes) {
    if (secondes == null) return '';
    final min = secondes ~/ 60;
    final sec = secondes % 60;
    if (min < 60) {
      return '${min}min ${sec.toString().padLeft(2, '0')}s';
    }
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.episode['format'] as String? ?? 'audio';
    final isGratuit = widget.episode['est_gratuit'] as bool? ?? true;
    final prix = widget.episode['prix'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Image hero avec overlay ────────────────
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 240,
                              color: AppColors.orange.withValues(alpha:0.15),
                              child: widget.episode['image_url'] != null
                                  ? Image.network(
                                      widget.episode['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildHeroPlaceholder(format),
                                    )
                                  : _buildHeroPlaceholder(format),
                            ),

                            // Overlay si payant et pas d'accès
                            if (!isGratuit && !_aAcces)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha:0.55),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_rounded,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Contenu payant',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$prix FCFA pour accéder',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha:0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Bouton retour
                            Positioned(
                              top: 12, left: 12,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                            // Badge format en haut à droite
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      format == 'audio'
                                          ? Icons.headphones_rounded
                                          : Icons.videocam_outlined,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      format == 'audio' ? 'AUDIO' : 'VIDÉO',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Nom de la série
                              Text(
                                widget.serieNom.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.orange,
                                  letterSpacing: 0.8,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Titre de l'épisode
                              Text(
                                widget.episode['titre'],
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textTitle,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Durée + badge accès
                              Row(
                                children: [
                                  if (widget.episode['duree_secondes'] != null) ...[
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuree(
                                        widget.episode['duree_secondes'] as int?,
                                      ),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  // Badge gratuit ou payant
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGratuit
                                          ? AppColors.green.withValues(alpha:0.1)
                                          : const Color(0xFF0A0A0A).withValues(alpha:0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isGratuit ? 'GRATUIT' : '$prix FCFA',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isGratuit
                                            ? AppColors.green
                                            : AppColors.textTitle,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Description
                              if (widget.episode['description'] != null) ...[
                                Text(
                                  widget.episode['description'],
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColors.textSubtitle,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // ── Zone lecteur / accès ───────────────

                              if (_aAcces) ...[
                                // Accès accordé
                                if (format == 'audio')
                                  // Player audio
                                  AudioPlayerWidget(
                                    audioUrl: widget.episode['url_media'],
                                    titre: widget.episode['titre'],
                                  )
                                else if (_youtubeController != null)
                                  // Player YouTube intégré in-app
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: YoutubePlayer(
                                          controller: _youtubeController!,
                                          showVideoProgressIndicator: true,
                                          progressIndicatorColor: AppColors.orange,
                                          progressColors: const ProgressBarColors(
                                            playedColor: AppColors.orange,
                                            handleColor: AppColors.orangeLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.fullscreen_rounded, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Appuyez sur ⛶ dans le lecteur pour plein écran',
                                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else if (_chewieController != null)
                                  // Lecteur vidéo direct (Supabase storage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: Chewie(controller: _chewieController!),
                                    ),
                                  )
                                else
                                  // Vidéo en cours de chargement ou URL non reconnue
                                  Center(
                                    child: SizedBox(
                                      height: 54,
                                      child: ElevatedButton.icon(
                                        onPressed: _ouvrirVideo,
                                        icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                                        label: Text('REGARDER LA VIDÉO', style: AppTextStyles.button),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.orange,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ] else ...[
                                // Pas d'accès — bouton achat
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 32,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Contenu exclusif',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textTitle,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accédez à cet épisode pour $prix FCFA',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textSubtitle,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _ouvrirPaiement,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0A0A0A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'ACHETER CET ÉPISODE — $prix FCFA',
                                            style: AppTextStyles.button,
                                          ),
                                        ),
                                      ),
                                    ],
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

  Widget _buildHeroPlaceholder(String format) {
    return Container(
      color: AppColors.orange.withValues(alpha:0.12),
      child: Center(
        child: Icon(
          format == 'audio'
              ? Icons.headphones_rounded
              : Icons.videocam_outlined,
          color: AppColors.orange,
          size: 64,
        ),
      ),
    );
  }

  // ── BottomSheet paiement épisode ──────────────────────────────────
  Widget _buildPaiementSheet() {
    final prix = widget.episode['prix'] as int? ?? 0;
    final frais = (prix * 0.01).round();
    final total = prix + 200 + frais;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      expand: false,
      builder: (_, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Acheter cet épisode',
              style: AppTextStyles.heading2,
            ),

            const SizedBox(height: 4),

            Text(
              widget.episode['titre'],
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSubtitle,
              ),
            ),

            const SizedBox(height: 20),

            // Récap montants
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                children: [
                  _ligneMontant('Épisode', '$prix FCFA'),
                  const SizedBox(height: 6),
                  _ligneMontant('Frais administratifs', '200 FCFA'),
                  const SizedBox(height: 6),
                  _ligneMontant('Frais Mobile Money', '$frais FCFA'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTitle,
                        ),
                      ),
                      Text(
                        '$total FCFA',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text('MODE DE PAIEMENT', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 10),

            // Opérateurs
            Row(
              children: _operateurs.map((op) {
                final isSelected = _operateur == op['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _operateur = op['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (op['color'] as Color).withValues(alpha:0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? op['color'] as Color
                              : AppColors.divider,
                          width: isSelected ? 2 : 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          op['label'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: op['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Bouton payer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _acheterEpisode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isPaying
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text('PAYER $total FCFA', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneMontant(String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          valeur,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textTitle,
          ),
        ),
      ],
    );
  }
}