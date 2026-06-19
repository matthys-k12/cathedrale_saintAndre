// Écran Mon Compte — version premium :
//
// SECTIONS :
// 1. Hero profil — avatar initiales bordeaux, nom, email/tel,
//    badges (Donateur Or, Paroissien), stats (dons + messes)
// 2. Dénier du Culte — statut de cotisation annuelle avec
//    indicateur payé/partiel/non payé + bouton payer si besoin
// 3. Historique unifié — dons + messes + casuels triés par date
//    avec icônes, montants et statuts colorés
// 4. Paramètres — sections organisées intelligemment
// 5. Partager l'app — card avec logo

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../auth/screens/login_screen.dart';
import '../../admin/screens/admin_screen.dart';
import '../../dons/screens/dons_screnn.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Données utilisateur
  Map<String, dynamic>? _profil;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _denierCulte;

  // Historique unifié (dons + messes + casuels)
  List<Map<String, dynamic>> _historique = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Charger en parallèle pour économiser du temps
      final results = await Future.wait([
        // Profil
        supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single(),

        // Dons récents
        supabase
            .from('dons')
            .select('id, campagne_titre, montant, statut, created_at, operateur_paiement')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10),

        // Demandes de messe récentes
        supabase
            .from('messe_demandes')
            .select('id, type_messe, date_messe, heure_messe, montant, statut, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10),

        // Casuels récents
        supabase
            .from('casuel_demandes')
            .select('id, label, montant, statut, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10),

        // Dénier du culte de l'année en cours
        supabase
            .from('denier_culte')
            .select()
            .eq('user_id', userId)
            .eq('annee', DateTime.now().year)
            .maybeSingle(),
      ]);

      if (!mounted) return;

      // Construire l'historique unifié
      final dons = (results[1] as List).map((d) => {
        ...Map<String, dynamic>.from(d),
        '_type': 'don',
        '_icon': Icons.favorite_outline_rounded,
        '_color': const Color(0xFF1D9E75),
        '_label': d['campagne_titre'],
      }).toList();

      final messes = (results[2] as List).map((m) => {
        ...Map<String, dynamic>.from(m),
        '_type': 'messe',
        '_icon': Icons.mail_outline_rounded,
        '_color': AppColors.primary,
        '_label': _labelTypeMesse(m['type_messe']),
      }).toList();

      final casuels = (results[3] as List).map((c) => {
        ...Map<String, dynamic>.from(c),
        '_type': 'casuel',
        '_icon': Icons.receipt_long_outlined,
        '_color': const Color(0xFFC9922A),
        '_label': c['label'],
      }).toList();

      // Fusionner et trier par date
      final all = [...dons, ...messes, ...casuels];
      all.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      // Calculer les stats
      final totalDons = (results[1] as List).fold<int>(
        0, (sum, d) => sum + (d['montant'] as int? ?? 0));
      final totalMesses = (results[2] as List).length;

      setState(() {
        _profil = results[0] as Map<String, dynamic>?;
        _stats = {
          'total_dons': totalDons,
          'total_messes': totalMesses,
        };
        _historique = all.take(8).toList(); // 8 dernières transactions
        _denierCulte = results[4] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _labelTypeMesse(String? type) {
    switch (type) {
      case 'action_de_grace': return 'Messe d\'Action de Grâce';
      case 'assistance_protection': return 'Messe d\'Assistance';
      case 'repos_ame': return 'Repos de l\'Âme';
      default: return 'Demande de Messe';
    }
  }

  // Initiales de l'utilisateur pour l'avatar
  String get _initiales {
    final nom = _profil?['nom']?.toString() ?? 'SA';
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.substring(0, nom.length >= 2 ? 2 : 1).toUpperCase();
  }

  // Vrai si le profil a is_admin = true dans Supabase
  // (ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;)
  bool get _isAdmin => _profil?['is_admin'] == true;

  // Badge utilisateur selon ses dons
  String get _badge {
    final total = _stats?['total_dons'] as int? ?? 0;
    if (total >= 100000) return 'Donateur Or';
    if (total >= 50000) return 'Donateur Argent';
    return 'Paroissien';
  }

  Color get _badgeColor {
    final total = _stats?['total_dons'] as int? ?? 0;
    if (total >= 100000) return AppColors.accent;
    if (total >= 50000) return AppColors.textSecondary;
    return AppColors.primary;
  }

  String _fmt(int montant) {
    final s = montant.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  String _dateRelative(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 30) return '${diff.inDays} jours';
    const mois = ['jan.', 'fév.', 'mar.', 'avr.', 'mai', 'juin',
                  'juil.', 'août', 'sep.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── 1. HERO PROFIL — pleine largeur, sans padding ────
              _buildHeroProfil(),

              const SizedBox(height: 24),

              // Sections inférieures — padding horizontal 20px
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 2. DÉNIER DU CULTE ───────────────────────
                    _buildDenierCulte(),

                    const SizedBox(height: 24),

                    // ── 3. HISTORIQUE ────────────────────────────
                    _buildHistorique(),

                    const SizedBox(height: 24),

                    // ── 4. ADMINISTRATION (visible admin seulement) ─
                    if (_isAdmin) ...[
                      _buildAdminButton(),
                      const SizedBox(height: 16),
                    ],

                    // ── 5. PARAMÈTRES (page dédiée) ─────────────
                    _buildParametresButton(),

                    const SizedBox(height: 16),

                    // ── 5. PARTAGER L'APP ────────────────────────
                    _buildPartagerApp(),

                    const SizedBox(height: 16),

                    // ── 6. DÉCONNEXION ───────────────────────────
                    _buildDeconnexion(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barre de progression vers le prochain badge ───────────────────
  Widget _buildBadgeProgress() {
    final total = _stats?['total_dons'] as int? ?? 0;
    final int cible;
    final String prochainBadge;

    if (total >= 100000) {
      // Déjà au niveau maximum
      return Text(
        'Niveau maximum atteint — Merci pour vos dons !',
        style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.75)),
        textAlign: TextAlign.center,
      );
    } else if (total >= 50000) {
      cible = 100000;
      prochainBadge = 'Donateur Or';
    } else {
      cible = 50000;
      prochainBadge = 'Donateur Argent';
    }

    final double pct = (total / cible).clamp(0.0, 1.0);
    final int restant = cible - total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vers $prochainBadge',
                style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.75)),
              ),
              Text(
                '${_fmt(restant)} restants',
                style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.75)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero profil — bloc marine solide ─────────────────────────────
  Widget _buildHeroProfil() {
    return Column(
      children: [
        // Conteneur pleine largeur — pas de marge négative
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              // Avatar — photo si disponible, sinon initiales marines
              GestureDetector(
                onTap: _ouvrirModificationProfil,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _profil?['avatar_url'] != null && (_profil!['avatar_url'] as String).isNotEmpty
                          ? Image.network(
                              _profil!['avatar_url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _initiales,
                                  style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _initiales,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                    ),
                    // Petite pastille crayon — indique l'édition possible
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profil?['nom'] ?? 'Paroissien',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profil?['telephone'] ?? '',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 10),
              // Badge niveau actuel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Text(
                  _badge.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Stats dons + messes (sous le gradient)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_outline_rounded,
                label: 'DONS TOTAUX',
                valeur: _fmt(_stats?['total_dons'] as int? ?? 0),
                color: const Color(0xFF1D9E75),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.mail_outline_rounded,
                label: 'MESSES',
                valeur: '${_stats?['total_messes'] ?? 0} Intentions',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String valeur,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // Chiffre Playfair 28px w800 couleur
          Text(
            valeur,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dénier du Culte ────────────────────────────────────────────────
  Widget _buildDenierCulte() {
    final annee = DateTime.now().year;
    final statut = _denierCulte?['statut'] ?? 'non_paye';
    final montant = _denierCulte?['montant'] as int? ?? 0;
    final isPaye = statut == 'paye';
    final isPartiel = statut == 'partiel';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isPaye) {
      statusColor = AppColors.success;
      statusLabel = 'PAYÉ';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isPartiel) {
      statusColor = AppColors.accent;
      statusLabel = 'PARTIEL';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = AppColors.error;
      statusLabel = 'NON PAYÉ';
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // En-tête
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.church_outlined,
                    color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dénier du Culte $annee',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Cotisation paroissiale annuelle',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: statusColor, fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Montant payé si partiel
          if (isPartiel) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            Text(
              'Montant versé : ${_fmt(montant)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Bouton paiement dénier
          if (!isPaye) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _payerDenierCulte,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    isPartiel ? 'Compléter mon paiement' : 'Payer maintenant',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Rediriger vers la page des dons pour payer le dénier du culte
  Future<void> _payerDenierCulte() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DonsScreen()),
    );
    // Recharger le statut après retour de la page dons
    if (mounted) _loadData();
  }

  // ── Historique unifié ──────────────────────────────────────────────
  Widget _buildHistorique() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historique', style: AppTextStyles.heading2),
            if (_historique.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _HistoriqueCompletScreen(
                      labelTypeMesse: _labelTypeMesse,
                      dateRelative: _dateRelative,
                    ),
                  ),
                ),
                child: Text(
                  'Tout voir',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (_historique.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Aucune transaction pour le moment',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _historique.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == _historique.length - 1;

                return _buildHistoriqueItem(item, isLast);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoriqueItem(Map<String, dynamic> item, bool isLast) {
    final color = item['_color'] as Color;
    final statut = item['statut'] as String? ?? 'en_attente';
    final isValide = statut == 'validee' || statut == 'validé';
    final montant = item['montant'] as int? ?? 0;
    final operateur = item['operateur_paiement'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // Dot coloré 8×8 éditorial
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 14),

          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['_label'] as String? ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateRelative(item['created_at'])}'
                  '${operateur.isNotEmpty ? ' · $operateur' : ''}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Montant Playfair 15px w700
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: montant.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]} ',
                  ),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: ' FCFA',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bouton Administration — visible uniquement si is_admin = true ──
  Widget _buildAdminButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administration',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Gérer le contenu de l\'application',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Bouton vers la page Paramètres ────────────────────────────────
  Widget _buildParametresButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _ParametresScreen(
              profil: _profil,
              onProfileUpdated: _loadData,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.ink, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Profil · Notifications · Légal',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitre(String titre) {
    return Text(
      titre.toUpperCase(),
      style: AppTextStyles.fieldLabel.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    );
  }

  // Section paramètres avec rows cliquables
  Widget _buildParamSection(List<_ParamItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14,
              ),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Icon(item.icon,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  item.trailing ??
                      (item.onTap != null
                          ? const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            )
                          : const SizedBox()),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Partager l'app ─────────────────────────────────────────────────
  Widget _buildPartagerApp() {
    return GestureDetector(
      onTap: () {
        Share.share(
          '✝ Cathédrale Saint André de Yopougon\n'
          '━━━━━━━━━━━━━━━━━━━━\n\n'
          'Je vous invite à rejoindre notre communauté paroissiale sur l\'application officielle 🙏\n\n'
          '📅 Horaires des messes & intentions\n'
          '📖 Texte & saint du jour\n'
          '📢 Annonces et actualités de la paroisse\n'
          '🎙️ Podcasts et homélies\n'
          '💝 Dons & denier du culte\n'
          '⛪ Casuel & demandes de sacrements\n\n'
          'Disponible gratuitement sur Android.\n\n'
          '━━━━━━━━━━━━━━━━━━━━\n'
          '🕊️ « Là où deux ou trois sont réunis en mon nom, je suis au milieu d\'eux. » — Mt 18,20',
          subject: '✝ Rejoins notre communauté — App Cathédrale St André',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Logo SA
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'SA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommander l\'app',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'PARTAGER LA PAROLE',
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.ios_share_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Déconnexion — bouton pill outline rouge 1.5px ─────────────────
  Widget _buildDeconnexion() {
    return GestureDetector(
      onTap: () async {
        await supabase.auth.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', false);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(
          child: Text(
            'Se déconnecter',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────
  void _ouvrirModificationProfil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _ModificationProfilSheet(
        profil: _profil,
        onSave: (nom, avatarUrl) async {
          final update = <String, dynamic>{'nom': nom};
          if (avatarUrl != null) update['avatar_url'] = avatarUrl;
          await supabase.from('profiles').update(update).eq('id', supabase.auth.currentUser!.id);
          if (mounted) {
            Navigator.of(context).pop();
            _loadData();
          }
        },
      ),
    );
  }

  void _ouvrirChangementMdp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _ChangementMdpSheet(
        onSave: (newMdp) async {
          await supabase.auth.updateUser(
            UserAttributes(password: newMdp),
          );
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mot de passe modifié avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _ouvrirDocument(String type) {
    final titres = {
      'CGU': 'Conditions Générales d\'Utilisation',
      'CGV': 'Conditions Générales de Vente',
      'confidentialite': 'Politique de confidentialité',
      'mentions': 'Mentions légales',
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
              Text(titres[type] ?? '', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Text(
                'Ce document sera fourni par la Cathédrale Saint André de Yopougon.',
                style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page Paramètres dédiée ───────────────────────────────────────────
class _ParametresScreen extends StatefulWidget {
  final Map<String, dynamic>? profil;
  final VoidCallback onProfileUpdated;

  const _ParametresScreen({
    required this.profil,
    required this.onProfileUpdated,
  });

  @override
  State<_ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<_ParametresScreen> {
  bool _notifAnnonces = true;
  bool _notifSaintJour = true;
  bool _notifTexteJour = false;
  bool _notifPodcast = true;

  static const _kAnnonces  = 'notif_annonces';
  static const _kSaintJour = 'notif_saint_jour';
  static const _kTexteJour = 'notif_texte_jour';
  static const _kPodcast   = 'notif_podcast';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifAnnonces  = p.getBool(_kAnnonces)  ?? true;
        _notifSaintJour = p.getBool(_kSaintJour) ?? true;
        _notifTexteJour = p.getBool(_kTexteJour) ?? false;
        _notifPodcast   = p.getBool(_kPodcast)   ?? true;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Mon Profil ───────────────────────────────
                    _buildSectionLabel('Mon Profil'),
                    const SizedBox(height: 8),
                    _buildSection([
                      _ParamItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Informations personnelles',
                        onTap: _ouvrirModificationProfil,
                      ),
                      _ParamItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Changer mon mot de passe',
                        onTap: _ouvrirChangementMdp,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Notifications ────────────────────────────
                    _buildSectionLabel('Notifications'),
                    const SizedBox(height: 8),
                    _buildNotifSection(),

                    const SizedBox(height: 20),

                    // ── Légal ────────────────────────────────────
                    _buildSectionLabel('Légal & Confidentialité'),
                    const SizedBox(height: 8),
                    _buildSection([
                      _ParamItem(
                        icon: Icons.description_outlined,
                        label: 'Conditions Générales d\'Utilisation',
                        onTap: () => _ouvrirDocument('CGU'),
                      ),
                      _ParamItem(
                        icon: Icons.receipt_outlined,
                        label: 'Conditions Générales de Vente',
                        onTap: () => _ouvrirDocument('CGV'),
                      ),
                      _ParamItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Politique de confidentialité',
                        onTap: () => _ouvrirDocument('confidentialite'),
                      ),
                      _ParamItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Mentions légales',
                        onTap: () => _ouvrirDocument('mentions'),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Application ──────────────────────────────
                    _buildSectionLabel('Application'),
                    const SizedBox(height: 8),
                    _buildSection([
                      _ParamItem(
                        icon: Icons.star_outline_rounded,
                        label: 'Noter l\'application',
                        onTap: () {},
                      ),
                      _ParamItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Version',
                        trailing: Text(
                          'v1.0.0',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Support ──────────────────────────────────
                    _buildSectionLabel('Support'),
                    const SizedBox(height: 8),
                    _buildSection([
                      _ParamItem(
                        icon: Icons.mail_outline_rounded,
                        label: 'Nous contacter',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ContactScreen(),
                          ),
                        ),
                      ),
                      _ParamItem(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Faire une suggestion',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ContactScreen(
                              typePredefini: 'suggestion',
                            ),
                          ),
                        ),
                      ),
                      _ParamItem(
                        icon: Icons.bug_report_outlined,
                        label: 'Signaler un bug',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ContactScreen(
                              typePredefini: 'bug',
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header avec bouton retour ────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.ink,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Paramètres',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String titre) {
    return Text(
      titre.toUpperCase(),
      style: AppTextStyles.fieldLabel.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    );
  }

  Widget _buildSection(List<_ParamItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.divider, width: 0.5),
                      ),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.label, style: AppTextStyles.bodyMedium)),
                  item.trailing ??
                      (item.onTap != null
                          ? const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            )
                          : const SizedBox()),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotifSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNotifToggle('Annonces paroissiales', Icons.campaign_outlined, _notifAnnonces,
              (v) { setState(() => _notifAnnonces = v); _savePref(_kAnnonces, v); }, isLast: false),
          _buildNotifToggle('Saint du jour', Icons.church_outlined, _notifSaintJour,
              (v) { setState(() => _notifSaintJour = v); _savePref(_kSaintJour, v); }, isLast: false),
          _buildNotifToggle('Texte du jour', Icons.menu_book_outlined, _notifTexteJour,
              (v) { setState(() => _notifTexteJour = v); _savePref(_kTexteJour, v); }, isLast: false),
          _buildNotifToggle('Podcasts', Icons.podcasts_rounded, _notifPodcast,
              (v) { setState(() => _notifPodcast = v); _savePref(_kPodcast, v); }, isLast: true),
        ],
      ),
    );
  }

  Widget _buildNotifToggle(String label, IconData icon, bool value, Function(bool) onChanged,
      {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  void _ouvrirModificationProfil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _ModificationProfilSheet(
        profil: widget.profil,
        onSave: (nom, avatarUrl) async {
          final update = <String, dynamic>{'nom': nom};
          if (avatarUrl != null) update['avatar_url'] = avatarUrl;
          await supabase.from('profiles').update(update).eq('id', supabase.auth.currentUser!.id);
          if (mounted) {
            Navigator.of(context).pop();
            widget.onProfileUpdated();
          }
        },
      ),
    );
  }

  void _ouvrirChangementMdp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _ChangementMdpSheet(
        onSave: (newMdp) async {
          await supabase.auth.updateUser(UserAttributes(password: newMdp));
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mot de passe modifié avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _ouvrirDocument(String type) {
    final titres = {
      'CGU': 'Conditions Générales d\'Utilisation',
      'CGV': 'Conditions Générales de Vente',
      'confidentialite': 'Politique de confidentialité',
      'mentions': 'Mentions légales',
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
              Text(titres[type] ?? '', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Text(
                'Ce document sera fourni par la Cathédrale Saint André de Yopougon.',
                style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modèle item paramètre ────────────────────────────────────────────
class _ParamItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ParamItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });
}

// ── Sheet modification profil ────────────────────────────────────────
class _ModificationProfilSheet extends StatefulWidget {
  final Map<String, dynamic>? profil;
  final Future<void> Function(String nom, String? avatarUrl) onSave;

  const _ModificationProfilSheet({
    required this.profil,
    required this.onSave,
  });

  @override
  State<_ModificationProfilSheet> createState() =>
      _ModificationProfilSheetState();
}

class _ModificationProfilSheetState extends State<_ModificationProfilSheet> {
  late TextEditingController _nomController;
  String? _newAvatarUrl;
  bool _uploadingAvatar = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.profil?['nom'] ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
    if (file == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final userId = supabase.auth.currentUser!.id;
      final path = 'avatars/$userId.$ext';
      await supabase.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      setState(() { _newAvatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}'; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur upload : ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = _newAvatarUrl ?? widget.profil?['avatar_url'] as String?;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Modifier mon profil', style: AppTextStyles.heading2),
            const SizedBox(height: 20),

            // Avatar — tap pour changer
            Center(
              child: GestureDetector(
                onTap: _pickAndUpload,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
                      clipBehavior: Clip.hardEdge,
                      child: _uploadingAvatar
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : currentAvatar != null && currentAvatar.isNotEmpty
                              ? Image.network(currentAvatar, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.textSecondary))
                              : const Icon(Icons.person, size: 36, color: AppColors.textSecondary),
                    ),
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Changer la photo', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 20),
            Text('NOM COMPLET', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _nomController,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  await widget.onSave(_nomController.text.trim(), _newAvatarUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text('ENREGISTRER', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Écran historique complet ─────────────────────────────────────────
class _HistoriqueCompletScreen extends StatefulWidget {
  final String Function(String?) labelTypeMesse;
  final String Function(String?) dateRelative;

  const _HistoriqueCompletScreen({
    required this.labelTypeMesse,
    required this.dateRelative,
  });

  @override
  State<_HistoriqueCompletScreen> createState() => _HistoriqueCompletScreenState();
}

class _HistoriqueCompletScreenState extends State<_HistoriqueCompletScreen> {
  List<Map<String, dynamic>> _historique = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait([
        supabase
            .from('dons')
            .select('id, campagne_titre, montant, statut, created_at, operateur_paiement')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        supabase
            .from('messe_demandes')
            .select('id, type_messe, date_messe, montant, statut, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        supabase
            .from('casuel_demandes')
            .select('id, label, montant, statut, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
      ]);

      final dons = (results[0] as List).map((d) => {
        ...Map<String, dynamic>.from(d),
        '_label': d['campagne_titre'],
        '_color': const Color(0xFF1D9E75),
      }).toList();

      final messes = (results[1] as List).map((m) => {
        ...Map<String, dynamic>.from(m),
        '_label': widget.labelTypeMesse(m['type_messe']),
        '_color': AppColors.primary,
      }).toList();

      final casuels = (results[2] as List).map((c) => {
        ...Map<String, dynamic>.from(c),
        '_label': c['label'],
        '_color': const Color(0xFFC9922A),
      }).toList();

      final all = [...dons, ...messes, ...casuels];
      all.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      if (mounted) setState(() { _historique = all; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 28),
        ),
        title: Text(
          'Historique',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: AppColors.divider),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _historique.isEmpty
              ? Center(
                  child: Text('Aucune transaction', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _historique.length,
                  itemBuilder: (_, i) {
                    final item = _historique[i];
                    final color = item['_color'] as Color;
                    final montant = item['montant'] as int? ?? 0;
                    final operateur = item['operateur_paiement'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['_label'] as String? ?? '',
                                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.dateRelative(item['created_at'])}${operateur.isNotEmpty ? ' · $operateur' : ''}',
                                  style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: montant.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ',
                                  ),
                                  style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                                TextSpan(
                                  text: ' FCFA',
                                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Écran Nous contacter / Suggestions ────────────────────────────────
class _ContactScreen extends StatefulWidget {
  final String? typePredefini;
  const _ContactScreen({this.typePredefini});

  @override
  State<_ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<_ContactScreen> {
  final _objetCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  late String _type;
  bool _isLoading = false;

  static const _types = [
    {'value': 'suggestion', 'label': 'Suggestion'},
    {'value': 'reclamation', 'label': 'Réclamation'},
    {'value': 'bug', 'label': 'Signalement de bug'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.typePredefini ?? 'suggestion';
  }

  @override
  void dispose() {
    _objetCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_objetCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir l\'objet et le message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('contact_messages').insert({
        'user_id': userId,
        'type': _type,
        'objet': _objetCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'est_lu': false,
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message envoyé. Merci pour votre retour !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Nous contacter',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Une question, une suggestion ou un problème ? Écrivez-nous, nous vous répondrons rapidement.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),

                    // Type
                    Text('Type de message', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _type,
                          isExpanded: true,
                          style: AppTextStyles.inputText,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                          items: _types.map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!),
                          )).toList(),
                          onChanged: (v) { if (v != null) setState(() => _type = v); },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Objet
                    Text('Objet', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _objetCtrl,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        hintText: 'Résumez en quelques mots…',
                        hintStyle: AppTextStyles.inputHint,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message
                    Text('Message', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 6,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre message en détail…',
                        hintStyle: AppTextStyles.inputHint,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _envoyer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Envoyer le message', style: AppTextStyles.button),
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

// ── Sheet changement mot de passe ────────────────────────────────────
class _ChangementMdpSheet extends StatefulWidget {
  final Function(String newMdp) onSave;

  const _ChangementMdpSheet({required this.onSave});

  @override
  State<_ChangementMdpSheet> createState() => _ChangementMdpSheetState();
}

class _ChangementMdpSheetState extends State<_ChangementMdpSheet> {
  final _newMdpController = TextEditingController();
  final _confirmMdpController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _newMdpController.dispose();
    _confirmMdpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
            Text('Changer le mot de passe',
                style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            _buildMdpField(
              'NOUVEAU MOT DE PASSE',
              _newMdpController,
              _obscure1,
              () => setState(() => _obscure1 = !_obscure1),
            ),
            const SizedBox(height: 16),
            _buildMdpField(
              'CONFIRMER LE MOT DE PASSE',
              _confirmMdpController,
              _obscure2,
              () => setState(() => _obscure2 = !_obscure2),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_newMdpController.text !=
                      _confirmMdpController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Les mots de passe ne correspondent pas'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (_newMdpController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Minimum 6 caractères'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  widget.onSave(_newMdpController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text('ENREGISTRER', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMdpField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}