// Admin — Demandes en attente : Messes, Casuels, Dons.
// L'admin peut valider ou refuser chaque demande.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class AdminDemandesScreen extends StatefulWidget {
  // 'messes' | 'casuels' | 'dons'
  final String type;
  const AdminDemandesScreen({super.key, required this.type});

  @override
  State<AdminDemandesScreen> createState() => _AdminDemandesScreenState();
}

class _AdminDemandesScreenState extends State<AdminDemandesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _filtre = 'en_attente'; // 'en_attente' | 'validee' | 'tout'

  String get _table => switch (widget.type) {
    'messes' => 'messe_demandes',
    'casuels' => 'casuel_demandes',
    _ => 'dons',
  };

  String get _titre => switch (widget.type) {
    'messes' => 'Messes',
    'casuels' => 'Casuels',
    _ => 'Dons',
  };

  Color get _color => switch (widget.type) {
    'messes' => AppColors.navy,
    'casuels' => AppColors.colorCasuels,
    _ => const Color(0xFF1D9E75),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      var query = supabase.from(_table).select();
      if (_filtre != 'tout') query = query.eq('statut', _filtre);
      final data = await query.order('created_at', ascending: false).limit(50);
      if (mounted) {
        setState(() { _items = List<Map<String, dynamic>>.from(data); _isLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _valider(String id) async {
    await supabase.from(_table).update({'statut': 'validee'}).eq('id', id);
    _load();
  }

  Future<void> _refuser(String id) async {
    await supabase.from(_table).update({'statut': 'refuse'}).eq('id', id);
    _load();
  }

  String _labelStatut(String? s) {
    switch (s) {
      case 'validee': return 'Validée';
      case 'refuse': return 'Refusée';
      default: return 'En attente';
    }
  }

  Color _colorStatut(String? s) {
    switch (s) {
      case 'validee': return AppColors.success;
      case 'refuse': return AppColors.error;
      default: return AppColors.accent;
    }
  }

  String _fmt(int? v) {
    if (v == null) return '—';
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  String _dateRelative(String? d) {
    if (d == null) return '';
    final date = DateTime.tryParse(d);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
  }

  String _labelItem(Map<String, dynamic> item) {
    switch (widget.type) {
      case 'messes':
        return item['type_messe']?.toString().replaceAll('_', ' ') ?? 'Messe';
      case 'casuels':
        return item['label'] ?? item['sous_type'] ?? 'Casuel';
      default:
        return item['campagne_titre'] ?? 'Don';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: _color,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(_titre, style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const Spacer(),
                  Text('${_items.length}', style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                  )),
                ],
              ),
            ),

            // ── Filtres ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  _filtreChip('En attente', 'en_attente'),
                  const SizedBox(width: 8),
                  _filtreChip('Validées', 'validee'),
                  const SizedBox(width: 8),
                  _filtreChip('Tout', 'tout'),
                ],
              ),
            ),

            // ── Liste ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _color))
                  : _items.isEmpty
                      ? Center(child: Text('Aucune demande',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildRow(_items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtreChip(String label, String value) {
    final active = _filtre == value;
    return GestureDetector(
      onTap: () { setState(() => _filtre = value); _load(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _color : AppColors.divider),
        ),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.textSecondary,
        )),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item) {
    final statut = item['statut'] as String?;
    final isEnAttente = statut == 'en_attente';
    final montant = item['montant'] as int?;
    final id = item['id'].toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne haut : label + statut + date
          Row(
            children: [
              Expanded(
                child: Text(_labelItem(item),
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _colorStatut(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_labelStatut(statut), style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w700, color: _colorStatut(statut),
                )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (montant != null) ...[
                Text(_fmt(montant), style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _color)),
                const SizedBox(width: 10),
              ],
              Text(_dateRelative(item['created_at']),
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              if (item['type_demandeur'] == 'pour_tiers' && item['nom_beneficiaire'] != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(item['nom_beneficiaire'], style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),

          // Boutons validation (uniquement si en attente)
          if (isEnAttente) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _refuser(id),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.error),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('Refuser', style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _valider(id),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('Valider', style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
