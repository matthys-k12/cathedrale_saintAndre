// Admin — Gestion des Annonces : liste + ajout + suppression.
// L'admin peut publier une annonce avec titre, contenu, catégorie et flag urgent.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class AdminAnnoncesScreen extends StatefulWidget {
  const AdminAnnoncesScreen({super.key});

  @override
  State<AdminAnnoncesScreen> createState() => _AdminAnnoncesScreenState();
}

class _AdminAnnoncesScreenState extends State<AdminAnnoncesScreen> {
  List<Map<String, dynamic>> _annonces = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'activites', 'label': 'Activités'},
    {'id': 'mariage', 'label': 'Mariage'},
    {'id': 'prieres', 'label': 'Prières'},
    {'id': 'ceb', 'label': 'CEB'},
    {'id': 'associations', 'label': 'Associations'},
    {'id': 'rappel_a_dieu', 'label': 'Rappel à Dieu'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await supabase
          .from('annonces')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) setState(() { _annonces = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _supprimer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer', style: AppTextStyles.heading2),
        content: const Text('Supprimer cette annonce définitivement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await supabase.from('annonces').delete().eq('id', id);
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: AppColors.primary,
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
                  Text('Annonces', style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _ouvrirFormulaire(),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Nouvelle', style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liste ────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _annonces.isEmpty
                      ? Center(
                          child: Text('Aucune annonce', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          itemCount: _annonces.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildRow(_annonces[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> a) {
    final isUrgent = a['est_urgent'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? AppColors.error.withOpacity(0.4) : AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isUrgent)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                        child: Text('URGENT', style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    Expanded(
                      child: Text(a['titre'] ?? '', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(a['contenu'] ?? '', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_dateRelative(a['created_at']),
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _supprimer(a['id'].toString()),
            child: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirFormulaire({Map<String, dynamic>? annonce}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppColors.background,
      builder: (_) => _AnnonceForm(
        categories: _categories,
        annonce: annonce,
        onSaved: () { Navigator.of(context).pop(); _load(); },
      ),
    );
  }
}

// ── Formulaire d'ajout / modification d'annonce ──────────────────────────
class _AnnonceForm extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? annonce;
  final VoidCallback onSaved;

  const _AnnonceForm({required this.categories, this.annonce, required this.onSaved});

  @override
  State<_AnnonceForm> createState() => _AnnonceFormState();
}

class _AnnonceFormState extends State<_AnnonceForm> {
  late final TextEditingController _titreCtrl;
  late final TextEditingController _contenuCtrl;
  late String _categorie;
  late bool _estUrgent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titreCtrl = TextEditingController(text: widget.annonce?['titre'] ?? '');
    _contenuCtrl = TextEditingController(text: widget.annonce?['contenu'] ?? '');
    _categorie = widget.annonce?['categorie'] ?? widget.categories.first['id'];
    _estUrgent = widget.annonce?['est_urgent'] ?? false;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titreCtrl.text.trim().isEmpty || _contenuCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'titre': _titreCtrl.text.trim(),
        'contenu': _contenuCtrl.text.trim(),
        'categorie': _categorie,
        'est_urgent': _estUrgent,
      };
      if (widget.annonce != null) {
        await supabase.from('annonces').update(data).eq('id', widget.annonce!['id']);
      } else {
        await supabase.from('annonces').insert(data);
      }
      widget.onSaved();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.annonce != null ? 'Modifier l\'annonce' : 'Nouvelle annonce',
              style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            Text('TITRE', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            _field(_titreCtrl, 'Ex: Retraite spirituelle de carême'),
            const SizedBox(height: 14),
            Text('CONTENU', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            _field(_contenuCtrl, 'Détails de l\'annonce…', maxLines: 4),
            const SizedBox(height: 14),
            Text('CATÉGORIE', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: widget.categories.map((cat) {
                final isActive = _categorie == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() => _categorie = cat['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(cat['label'],
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _estUrgent = !_estUrgent),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _estUrgent ? AppColors.error : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _estUrgent ? AppColors.error : AppColors.divider, width: 1.5),
                    ),
                    child: _estUrgent ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 10),
                  Text('Marquer comme urgente', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('PUBLIER', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: hint, hintStyle: AppTextStyles.inputHint,
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
