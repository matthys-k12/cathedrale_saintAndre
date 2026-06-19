// Écran Texte du Jour — version enrichie :
// - Header avec référence biblique et date
// - Verset de l'évangile mis en valeur (card bordeaux)
// - Contenu de la lecture avec typographie lecture confortable
// - Section "Méditation" avec fond doré
// - Bouton partage

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_config.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class TexteJourScreen extends StatefulWidget {
  const TexteJourScreen({super.key});

  @override
  State<TexteJourScreen> createState() => _TexteJourScreenState();
}

class _TexteJourScreenState extends State<TexteJourScreen> {
  Map<String, dynamic>? _texte;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTexte();
  }

  Future<void> _loadTexte() async {
    try {
      // Chercher le texte d'aujourd'hui
      final today = DateTime.now().toIso8601String().substring(0, 10);

      List<dynamic> data = await supabase
          .from('texte_jour')
          .select()
          .eq('date_lecture', today)
          .limit(1);

      // Si pas de texte pour aujourd'hui, prendre le plus récent
      if (data.isEmpty) {
        data = await supabase
            .from('texte_jour')
            .select()
            .order('date_lecture', ascending: false)
            .limit(1);
      }

      if (mounted && data.isNotEmpty) {
        setState(() {
          _texte = Map<String, dynamic>.from(data.first);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateFr(String? dateStr) {
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
    if (_texte == null) return;

    final sb = StringBuffer();
    sb.writeln('📖 TEXTE DU JOUR · ${_formatDateFr(_texte!['date_lecture']).toUpperCase()}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln();
    sb.writeln('📚 ${_texte!['titre']}');
    sb.writeln('Référence : ${_texte!['reference']}');
    sb.writeln();
    if (_texte!['evangile'] != null) {
      sb.writeln('🙏 « ${_texte!['evangile']} »');
      sb.writeln();
    }
    sb.writeln('📲 Lire la lecture complète :');
    sb.writeln(partageTexteJour);
    sb.writeln();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📱 Cathédrale St André · Yopougon');
    sb.write('(L\'app doit être installée pour ouvrir le lien)');

    await Share.share(
      sb.toString(),
      subject: 'Texte du jour — ${_texte!['reference']}',
    );
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

    if (_texte == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Texte du jour'),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Text('Aucun texte disponible', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ── Header sticky ────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Retour',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Badge date
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDateFr(_texte!['date_lecture']).toUpperCase(),
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Titre en serif
                    Text(
                      _texte!['titre'],
                      style: AppTextStyles.heading1,
                    ),

                    const SizedBox(height: 6),

                    // Référence biblique
                    Text(
                      _texte!['reference'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Verset de l'évangile mis en valeur ────────
                    if (_texte!['evangile'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label "ÉVANGILE DU JOUR"
                            Text(
                              'ÉVANGILE DU JOUR',
                              style: AppTextStyles.fieldLabel.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Verset
                            Text(
                              '"${_texte!['evangile']}"',
                              style: AppTextStyles.quote.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Séparateur "La Lecture" ────────────────────
                    Row(
                      children: [
                        Container(
                          width: 4, height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('La Lecture', style: AppTextStyles.heading2),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Contenu de la lecture ──────────────────────
                    ..._texte!['contenu']
                        .toString()
                        .split('\n\n')
                        .map<Widget>((para) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          para.trim(),
                          style: AppTextStyles.bodyLarge.copyWith(
                            height: 1.85,
                          ),
                        ),
                      );
                    }).toList(),

                    // ── Méditation — jaune + 4px border rouge ─────
                    if (_texte!['reflexion'] != null) ...[
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Eyebrow "Méditation" en rouge
                            Text(
                              'Méditation',
                              style: AppTextStyles.fieldLabel.copyWith(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _texte!['reflexion'],
                              style: AppTextStyles.quote.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],

                    // ── Bouton partage ─────────────────────────────
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
      ),
    );
  }
}