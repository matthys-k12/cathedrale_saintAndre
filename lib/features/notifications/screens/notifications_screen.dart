// Écran Notifications — affiche les annonces récentes et les mises à jour
// de transactions (messes, dons, casuels) de l'utilisateur.
// Les items non lus sont marqués avec un dot rouge.
// La date de dernière lecture est stockée localement.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotifItem> _items = [];
  bool _isLoading = true;

  // Clé SharedPreferences pour la date de dernière lecture
  static const _prefKey = 'notifs_last_seen';

  late DateTime _lastSeen;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt(_prefKey) ?? 0;
    _lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
    await _loadNotifications();

    // Marquer tout comme lu après affichage
    await prefs.setInt(_prefKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      // Charger en parallèle : annonces + transactions utilisateur
      final futures = await Future.wait([
        // Annonces des 30 derniers jours
        supabase
            .from('annonces')
            .select('id, titre, contenu, created_at, est_urgent')
            .order('created_at', ascending: false)
            .limit(20),

        // Messes en attente ou récemment mises à jour
        if (userId != null)
          supabase
              .from('messe_demandes')
              .select('id, type_messe, statut, created_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(10)
        else
          Future.value(<dynamic>[]),

        // Dons récents
        if (userId != null)
          supabase
              .from('dons')
              .select('id, campagne_titre, statut, montant, created_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(10)
        else
          Future.value(<dynamic>[]),
      ]);

      final annonces = (futures[0] as List).map((a) => _NotifItem(
        id: 'annonce_${a['id']}',
        type: _NotifType.annonce,
        titre: a['titre'] as String,
        sousTitre: (a['contenu'] as String).length > 80
            ? '${(a['contenu'] as String).substring(0, 80)}…'
            : a['contenu'] as String,
        date: DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now(),
        isUrgent: a['est_urgent'] == true,
      )).toList();

      final messes = (futures[1] as List).map((m) => _NotifItem(
        id: 'messe_${m['id']}',
        type: _NotifType.messe,
        titre: 'Demande de messe',
        sousTitre: _labelStatut(m['statut']),
        date: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
        isUrgent: false,
        statut: m['statut'] as String?,
      )).toList();

      final dons = (futures[2] as List).map((d) => _NotifItem(
        id: 'don_${d['id']}',
        type: _NotifType.don,
        titre: d['campagne_titre'] as String? ?? 'Don',
        sousTitre: _labelStatut(d['statut']),
        date: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
        isUrgent: false,
        statut: d['statut'] as String?,
      )).toList();

      final all = [...annonces, ...messes, ...dons]
        ..sort((a, b) => b.date.compareTo(a.date));

      if (mounted) setState(() { _items = all; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _labelStatut(String? statut) {
    switch (statut) {
      case 'validee':
      case 'validé': return 'Votre demande a été validée ✓';
      case 'en_attente': return 'En cours de traitement…';
      case 'refuse': return 'Demande refusée';
      default: return 'Mise à jour de statut';
    }
  }

  String _dateRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    const mois = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin',
                  'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${mois[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
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
                    'Notifications',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    Text(
                      '${_items.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // ── Corps ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _items.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: AppColors.divider, height: 0.5, indent: 20, endIndent: 20,
                          ),
                          itemBuilder: (_, i) => _buildItem(_items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_NotifItem item) {
    final isUnread = item.date.isAfter(_lastSeen);
    final color = _colorType(item.type);
    final icon = _iconType(item.type);

    return Container(
      color: isUnread ? color.withOpacity(0.03) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône type
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.titre,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isUrgent)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'URGENT',
                          style: GoogleFonts.dmSans(
                            fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.sousTitre,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  _dateRelative(item.date),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Dot non lu
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 32, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'Les annonces et mises à jour\napparaîtront ici.',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _colorType(_NotifType type) {
    switch (type) {
      case _NotifType.annonce: return AppColors.primary;
      case _NotifType.messe: return AppColors.navy;
      case _NotifType.don: return const Color(0xFF1D9E75);
    }
  }

  IconData _iconType(_NotifType type) {
    switch (type) {
      case _NotifType.annonce: return Icons.campaign_outlined;
      case _NotifType.messe: return Icons.mail_outline_rounded;
      case _NotifType.don: return Icons.favorite_outline_rounded;
    }
  }
}

enum _NotifType { annonce, messe, don }

class _NotifItem {
  final String id;
  final _NotifType type;
  final String titre;
  final String sousTitre;
  final DateTime date;
  final bool isUrgent;
  final String? statut;

  const _NotifItem({
    required this.id,
    required this.type,
    required this.titre,
    required this.sousTitre,
    required this.date,
    required this.isUrgent,
    this.statut,
  });
}
