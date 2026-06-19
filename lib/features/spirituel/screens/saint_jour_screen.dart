import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_config.dart';
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

  Future<void> _partagerWhatsApp() async {
    if (_saint == null) return;

    final sb = StringBuffer();
    sb.writeln('✝ SAINT DU JOUR · ${_formatDate(_saint!['fete_date']).toUpperCase()}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln();
    sb.writeln('🌟 ${_saint!['nom']}');
    if (_saint!['sous_titre'] != null) sb.writeln(_saint!['sous_titre']);
    sb.writeln();
    if (_saint!['citation'] != null) {
      sb.writeln('💬 « ${_saint!['citation']} »');
      sb.writeln();
    }
    sb.writeln('📲 Lire la biographie complète :');
    sb.writeln(partageSaintJour);
    sb.writeln();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.write('📱 Cathédrale St André · Yopougon');

    await Share.share(
      sb.toString(),
      subject: 'Saint du jour — ${_saint!['nom']}',
    );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
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
              child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Container(
                  width: double.infinity,
                  height: 280,
                  color: AppColors.bleuMarial,
                  child: _saint!['image_url'] != null
                      ? Image.network(
                          _saint!['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                ),

                // Bloc bleu : kicker + nom + sous-titre
                Container(
                  width: double.infinity,
                  color: AppColors.bleuMarial,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAINT DU JOUR · ${_formatDate(_saint!['fete_date']).toUpperCase()}',
                        style: AppTextStyles.fieldLabel.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _saint!['nom'],
                        style: AppTextStyles.headingOnDark.copyWith(
                          fontSize: 28,
                          letterSpacing: -0.3,
                          height: 1.05,
                        ),
                      ),
                      if (_saint!['sous_titre'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saint!['sous_titre'],
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu textuel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Citation
                  if (_saint!['citation'] != null) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Citation',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '« ${_saint!['citation']} »',
                            style: AppTextStyles.quote.copyWith(
                              fontSize: 18,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Séparateur Biographie
                  Row(
                    children: [
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

                  // Texte biographie
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

                  // Bouton partage WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _partagerWhatsApp,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text('PARTAGER SUR WHATSAPP', style: AppTextStyles.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
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
