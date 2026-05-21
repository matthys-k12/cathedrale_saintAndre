// Écran Saint du Jour — version améliorée :
// - Grande image immersive plein écran avec overlay dégradé
// - Badge date de fête liturgique
// - Citation du saint dans une card dorée
// - Biographie avec typographie soignée
// - Bouton partage WhatsApp
// - Navigation retour transparente sur l'image

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class SaintJourScreen extends StatefulWidget {
  const SaintJourScreen({super.key});

  @override
  State<SaintJourScreen> createState() => _SaintJourScreenState();
}

class _SaintJourScreenState extends State<SaintJourScreen> {
  Map<String, dynamic>? _saint;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaint();
  }

  Future<void> _loadSaint() async {
    try {
      // Chercher le saint dont la fête correspond à aujourd'hui
      // Si pas trouvé, prendre le dernier inséré
      final today =
          '${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

      List<dynamic> data = await supabase
          .from('saint_jour')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (mounted && data.isNotEmpty) {
        setState(() {
          _saint = Map<String, dynamic>.from(data.first);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Partager sur WhatsApp
  Future<void> _partagerWhatsApp() async {
    if (_saint == null) return;
    final texte = Uri.encodeComponent(
      '🙏 Saint du jour — ${_saint!['nom']}\n\n'
      '"${_saint!['citation'] ?? ''}"\n\n'
      'Application Saint André Yopougon',
    );
    final url = Uri.parse('https://wa.me/?text=$texte');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${mois[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_saint == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Saint du jour')),
        body: Center(
          child: Text(
            'Contenu non disponible',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      // extendBodyBehindAppBar permet à l'image de passer
      // derrière la barre de status (haut de l'écran)
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Bouton retour blanc sur fond d'image
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // Bouton partage en haut à droite
        actions: [
          GestureDetector(
            onTap: _partagerWhatsApp,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          // ── Image hero immersive ─────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Image du saint — pleine largeur, haute
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    image: _saint!['image_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(_saint!['image_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  // Placeholder si pas d'image
                  child: _saint!['image_url'] == null
                      ? Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        )
                      : null,
                ),

                // Dégradé du bas — transition vers fond blanc
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),

                // Card nom + sous-titre flottante sur l'image
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge date liturgique
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatDate(_saint!['fete_date']).toUpperCase(),
                                style: AppTextStyles.fieldLabel.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Nom du saint en grand serif
                            Text(
                              _saint!['nom'],
                              style: AppTextStyles.heading1.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 30,
                              ),
                            ),
                            // Sous-titre (Apôtre et Martyr...)
                            if (_saint!['sous_titre'] != null)
                              Text(
                                _saint!['sous_titre'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu textuel ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Citation du saint ──────────────────────────
                  if (_saint!['citation'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.accent,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Text(
                        '"${_saint!['citation']}"',
                        style: AppTextStyles.quote.copyWith(
                          fontSize: 15,
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Séparateur "Biographie" ────────────────────
                  Row(
                    children: [
                      // Barre bordeaux décorative
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Biographie', style: AppTextStyles.heading2),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Texte biographie ───────────────────────────
                  // Paragraphes séparés par les \n\n
                  ..._saint!['biographie']
                      .toString()
                      .split('\n\n')
                      .map<Widget>((para) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        para.trim(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          height: 1.75,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // ── Bouton partage WhatsApp ────────────────────
                  SizedBox(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}