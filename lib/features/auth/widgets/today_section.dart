import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../../features/spirituel/screens/saint_jour_screen.dart';
import '../../../features/spirituel/screens/text_jour_screen.dart';

class TodaySection extends StatefulWidget {
  const TodaySection({super.key});

  @override
  State<TodaySection> createState() => _TodaySectionState();
}

class _TodaySectionState extends State<TodaySection> {
  String? _imageTexte;
  String? _imageSaint;
  String? _titreTexte;
  String? _titreSaint;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Texte du jour — date du jour, fallback au plus récent
    Map<String, dynamic>? texte;
    try {
      final d = await supabase
          .from('texte_jour')
          .select('titre, image_url')
          .eq('date_lecture', today)
          .limit(1);
      if ((d as List).isNotEmpty) texte = Map<String, dynamic>.from(d.first);
    } catch (_) {}

    if (texte == null) {
      try {
        final d = await supabase
            .from('texte_jour')
            .select('titre, image_url')
            .order('date_lecture', ascending: false)
            .limit(1);
        if ((d as List).isNotEmpty) texte = Map<String, dynamic>.from(d.first);
      } catch (_) {}
    }

    // Saint du jour — toujours le plus récent
    Map<String, dynamic>? saint;
    try {
      final d = await supabase
          .from('saint_jour')
          .select('nom, image_url')
          .order('created_at', ascending: false)
          .limit(1);
      if ((d as List).isNotEmpty) saint = Map<String, dynamic>.from(d.first);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _titreTexte = texte?['titre'] as String?;
        _imageTexte = texte?['image_url'] as String?;
        _titreSaint = saint?['nom'] as String?;
        _imageSaint = saint?['image_url'] as String?;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aujourd'hui",
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TodayCard(
                  color: AppColors.bleuMarial,
                  label: 'TEXTE DU JOUR',
                  title: _titreTexte ?? 'Lecture du\njour',
                  imageUrl: _imageTexte,
                  loading: _loading,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TexteJourScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayCard(
                  color: AppColors.navy,
                  label: 'SAINT DU JOUR',
                  title: _titreSaint ?? 'Saint du\njour',
                  imageUrl: _imageSaint,
                  loading: _loading,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SaintJourScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Color color;
  final String label;
  final String title;
  final String? imageUrl;
  final bool loading;
  final VoidCallback onTap;

  const _TodayCard({
    required this.color,
    required this.label,
    required this.title,
    required this.loading,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone photo
            SizedBox(
              height: 100,
              width: double.infinity,
              child: _buildImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.2,
                      letterSpacing: -0.2,
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

  Widget _buildImage() {
    // Chargement en cours → shimmer coloré
    if (loading) {
      return Container(
        color: color.withValues(alpha: 0.6),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // Image disponible
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: color.withValues(alpha: 0.6),
            child: const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(color: color),
      );
    }

    // Pas d'image → couleur solide
    return Container(color: color);
  }
}
