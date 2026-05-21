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
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../auth/screens/login_screen.dart';

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

  // Notifications — état local (en prod, sauvegardé dans Supabase)
  bool _notifAnnonces = true;
  bool _notifSaintJour = true;
  bool _notifTexteJour = false;
  bool _notifPodcast = true;

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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── 1. HERO PROFIL ───────────────────────────────────
              _buildHeroProfil(),

              const SizedBox(height: 24),

              // ── 2. DÉNIER DU CULTE ───────────────────────────────
              _buildDenierCulte(),

              const SizedBox(height: 24),

              // ── 3. HISTORIQUE ────────────────────────────────────
              _buildHistorique(),

              const SizedBox(height: 24),

              // ── 4. PARAMÈTRES ────────────────────────────────────
              _buildParametres(),

              const SizedBox(height: 24),

              // ── 5. PARTAGER L'APP ────────────────────────────────
              _buildPartagerApp(),

              const SizedBox(height: 16),

              // ── 6. DÉCONNEXION ───────────────────────────────────
              _buildDeconnexion(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero profil ────────────────────────────────────────────────────
  Widget _buildHeroProfil() {
    return Column(
      children: [
        // Avatar avec initiales
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initiales,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nom complet
        Text(
          _profil?['nom'] ?? 'Paroissien',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Téléphone
        Text(
          _profil?['telephone'] ?? '',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge dynamique selon les dons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _badgeColor.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                _badge.toUpperCase(),
                style: AppTextStyles.fieldLabel.copyWith(
                  color: _badgeColor,
                  fontSize: 10,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Badge Paroissien fixe
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'PAROISSIEN',
                style: AppTextStyles.fieldLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Stats dons + messes
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.fieldLabel),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
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

          // Bouton payer si non payé ou partiel
          if (!isPaye) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _payerDenierCulte(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isPartiel ? 'COMPLÉTER MON PAIEMENT' : 'PAYER MAINTENANT',
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Payer le dénier du culte
  Future<void> _payerDenierCulte() async {
    // Montant suggéré du dénier (configurable par l'admin)
    const montantSuggere = 5000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _DenierPaiementSheet(
        montantSuggere: montantSuggere,
        onPayer: (montant, operateur) async {
          try {
            final userId = supabase.auth.currentUser?.id;
            if (userId == null) return;

            final annee = DateTime.now().year;

            // Upsert — crée ou met à jour la cotisation
            await supabase.from('denier_culte').upsert({
              'user_id': userId,
              'annee': annee,
              'montant': montant,
              'statut': montant >= montantSuggere ? 'paye' : 'partiel',
              'date_paiement': DateTime.now().toIso8601String(),
              'operateur_paiement': operateur,
            });

            if (mounted) {
              Navigator.of(context).pop();
              _loadData(); // Recharger les données

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    montant >= montantSuggere
                        ? 'Dénier du culte payé. Merci !'
                        : 'Paiement partiel enregistré.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors du paiement'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
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
              Text(
                'Tout voir',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
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
          // Icône type de transaction
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['_icon'] as IconData, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          // Label + date + opérateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['_label'] as String? ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_dateRelative(item['created_at'])}'
                  '${operateur.isNotEmpty ? ' • $operateur' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Montant + statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_fmt(montant)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              // Icône statut
              Icon(
                isValide
                    ? Icons.check_circle_outline_rounded
                    : Icons.access_time_rounded,
                size: 14,
                color: isValide ? AppColors.success : AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Paramètres organisés en sections ──────────────────────────────
  Widget _buildParametres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Section : Dénier du Culte (statut uniquement) ────────────
        _buildSectionTitre('Dénier du Culte ${DateTime.now().year}'),
        const SizedBox(height: 8),
        _buildDenierStatut(),

        const SizedBox(height: 16),

        // ── Section : Mon profil ─────────────────────────────────────
        _buildSectionTitre('Mon Profil'),
        const SizedBox(height: 8),
        _buildParamSection([
          _ParamItem(
            icon: Icons.person_outline_rounded,
            label: 'Informations personnelles',
            onTap: () => _ouvrirModificationProfil(),
          ),
          _ParamItem(
            icon: Icons.lock_outline_rounded,
            label: 'Changer mon mot de passe',
            onTap: () => _ouvrirChangementMdp(),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Section : Notifications ──────────────────────────────────
        _buildSectionTitre('Notifications'),
        const SizedBox(height: 8),
        _buildNotifSection(),

        const SizedBox(height: 16),

        // ── Section : Légal ──────────────────────────────────────────
        _buildSectionTitre('Légal & Confidentialité'),
        const SizedBox(height: 8),
        _buildParamSection([
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

        const SizedBox(height: 16),

        // ── Section : Application ────────────────────────────────────
        _buildSectionTitre('Application'),
        const SizedBox(height: 8),
        _buildParamSection([
          _ParamItem(
            icon: Icons.star_outline_rounded,
            label: 'Noter l\'application',
            onTap: () {},
          ),
          _ParamItem(
            icon: Icons.bug_report_outlined,
            label: 'Signaler un problème',
            onTap: () {},
          ),
          _ParamItem(
            icon: Icons.info_outline_rounded,
            label: 'Version 1.0.0',
            onTap: null,
            trailing: Text(
              'v1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // Affiche le statut du dénier du culte dans les paramètres.
  // Informatif seulement — pas de bouton payer ici.
  // Le paiement se fait depuis Dons & Dénier du Culte.
  Widget _buildDenierStatut() {
    final annee = DateTime.now().year;
    final statut = _denierCulte?['statut'] ?? 'non_paye';
    final montant = _denierCulte?['montant'] as int? ?? 0;
    final isPaye = statut == 'paye';
    final isPartiel = statut == 'partiel';

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;
    final String messageDetail;

    if (isPaye) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Payé';
      messageDetail = 'Votre cotisation $annee est à jour. Merci !';
    } else if (isPartiel) {
      statusColor = AppColors.accent;
      statusIcon = Icons.timelapse_rounded;
      statusLabel = 'Partiel';
      messageDetail =
          '${_fmt(montant)} versés. Complétez votre cotisation depuis "Dons & Dénier du Culte".';
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Non payé';
      messageDetail =
          'Vous n\'avez pas encore cotisé pour $annee. '
          'Rendez-vous dans "Dons & Dénier du Culte".';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dénier du Culte',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: statusColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  messageDetail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                if (!isPaye) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Accédez à "Dons & Dénier du Culte" depuis l\'accueil',
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Payer maintenant',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: statusColor,
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

  // Section notifications avec toggles
  Widget _buildNotifSection() {
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
        children: [
          _buildNotifToggle(
            'Annonces paroissiales',
            Icons.campaign_outlined,
            _notifAnnonces,
            (v) => setState(() => _notifAnnonces = v),
            isLast: false,
          ),
          _buildNotifToggle(
            'Saint du jour',
            Icons.church_outlined,
            _notifSaintJour,
            (v) => setState(() => _notifSaintJour = v),
            isLast: false,
          ),
          _buildNotifToggle(
            'Texte du jour',
            Icons.menu_book_outlined,
            _notifTexteJour,
            (v) => setState(() => _notifTexteJour = v),
            isLast: false,
          ),
          _buildNotifToggle(
            'Podcasts',
            Icons.podcasts_rounded,
            _notifPodcast,
            (v) => setState(() => _notifPodcast = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifToggle(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── Partager l'app ─────────────────────────────────────────────────
  Widget _buildPartagerApp() {
    return GestureDetector(
      onTap: () {
        // TODO : partager le lien Play Store
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

  // ── Déconnexion ────────────────────────────────────────────────────
  Widget _buildDeconnexion() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          await supabase.auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
          color: AppColors.error,
        ),
        label: Text(
          'Se déconnecter',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.error.withOpacity(0.4),
            width: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        onSave: (nom) async {
          await supabase.from('profiles').update({'nom': nom}).eq(
              'id', supabase.auth.currentUser!.id);
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

// ── Sheet paiement dénier du culte ───────────────────────────────────
class _DenierPaiementSheet extends StatefulWidget {
  final int montantSuggere;
  final Function(int montant, String operateur) onPayer;

  const _DenierPaiementSheet({
    required this.montantSuggere,
    required this.onPayer,
  });

  @override
  State<_DenierPaiementSheet> createState() => _DenierPaiementSheetState();
}

class _DenierPaiementSheetState extends State<_DenierPaiementSheet> {
  int _montant = 0;
  String _operateur = 'wave';
  final _montantController = TextEditingController();

  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave', 'label': 'Wave', 'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange\nMoney', 'color': const Color(0xFFFF6600)},
    {'id': 'mtn', 'label': 'MTN\nMoMo', 'color': const Color(0xFFFFCC00)},
    {'id': 'moov', 'label': 'Moov\nMoney', 'color': const Color(0xFF0066CC)},
  ];

  int get _montantEffectif {
    if (_montant > 0) return _montant;
    return int.tryParse(_montantController.text) ?? 0;
  }

  @override
  void dispose() {
    _montantController.dispose();
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
            Text('Dénier du Culte ${DateTime.now().year}',
                style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            Text(
              'Montant suggéré : ${widget.montantSuggere} FCFA',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Pills montants
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [1000, 2500, 5000, 10000].map((m) {
                final isSelected = _montant == m;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _montant = m;
                      _montantController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      '$m F',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Montant libre
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _montant = 0),
              decoration: InputDecoration(
                hintText: 'Autre montant (F CFA)',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.surface,
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
            const SizedBox(height: 20),
            Text('MODE DE PAIEMENT', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 10),
            Row(
              children: _operateurs.map((op) {
                final isSelected = _operateur == op['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _operateur = op['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (op['color'] as Color).withOpacity(0.12)
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
                          op['label'],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: op['color'] as Color,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _montantEffectif < 100
                    ? null
                    : () => widget.onPayer(_montantEffectif, _operateur),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.divider,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text('PAYER MAINTENANT', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet modification profil ────────────────────────────────────────
class _ModificationProfilSheet extends StatefulWidget {
  final Map<String, dynamic>? profil;
  final Function(String nom) onSave;

  const _ModificationProfilSheet({
    required this.profil,
    required this.onSave,
  });

  @override
  State<_ModificationProfilSheet> createState() =>
      _ModificationProfilSheetState();
}

class _ModificationProfilSheetState
    extends State<_ModificationProfilSheet> {
  late TextEditingController _nomController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(
      text: widget.profil?['nom'] ?? '',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
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
            Text('Modifier mon profil', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            Text('NOM COMPLET', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _nomController,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => widget.onSave(_nomController.text.trim()),
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