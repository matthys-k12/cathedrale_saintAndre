// Admin — Gestion des Actualités : liste + ajout d'articles.
// Chaque actualité contient : titre, article, max 10 photos OU 1 vidéo (URL).
// Les URLs de photos sont saisies manuellement (intégration upload à prévoir).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class AdminActualitesScreen extends StatefulWidget {
  const AdminActualitesScreen({super.key});

  @override
  State<AdminActualitesScreen> createState() => _AdminActualitesScreenState();
}

class _AdminActualitesScreenState extends State<AdminActualitesScreen> {
  List<Map<String, dynamic>> _actualites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await supabase
          .from('actualites')
          .select('id, titre, article, est_a_la_une, created_at, video_url')
          .order('created_at', ascending: false)
          .limit(30);
      if (mounted) {
        setState(() {
          _actualites = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _supprimer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer', style: AppTextStyles.heading2),
        content: const Text('Supprimer cet article définitivement ?'),
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
    await supabase.from('actualite_photos').delete().eq('actualite_id', id);
    await supabase.from('actualites').delete().eq('id', id);
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
              color: AppColors.green,
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
                  Text('Actualités', style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const Spacer(),
                  GestureDetector(
                    onTap: _ouvrirFormulaire,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text('Nouvel article', style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green,
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
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _actualites.isEmpty
                      ? Center(child: Text('Aucun article publié',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          itemCount: _actualites.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildRow(_actualites[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> a) {
    final aLaUne = a['est_a_la_une'] == true;
    final hasVideo = (a['video_url'] as String?)?.isNotEmpty == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: aLaUne ? AppColors.accent.withOpacity(0.5) : AppColors.divider,
          width: aLaUne ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Miniature couleur
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: aLaUne ? AppColors.accent.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasVideo ? Icons.play_circle_outline_rounded : Icons.article_outlined,
              color: aLaUne ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (aLaUne)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('À LA UNE', style: GoogleFonts.dmSans(
                          fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
                      ),
                    Expanded(
                      child: Text(a['titre'] ?? '',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(a['article'] ?? '',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
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

  void _ouvrirFormulaire() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppColors.background,
      builder: (_) => _ActualiteForm(onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }
}

// ── Formulaire de création d'actualité ───────────────────────────────────
class _ActualiteForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _ActualiteForm({required this.onSaved});

  @override
  State<_ActualiteForm> createState() => _ActualiteFormState();
}

class _ActualiteFormState extends State<_ActualiteForm> {
  final _titreCtrl = TextEditingController();
  final _articleCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final List<TextEditingController> _photosCtrls = [TextEditingController()];

  bool _aLaUne = false;
  bool _useVideo = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _articleCtrl.dispose();
    _videoCtrl.dispose();
    for (final c in _photosCtrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_titreCtrl.text.trim().isEmpty || _articleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final result = await supabase.from('actualites').insert({
        'titre': _titreCtrl.text.trim(),
        'article': _articleCtrl.text.trim(),
        'est_a_la_une': _aLaUne,
        'video_url': _useVideo ? _videoCtrl.text.trim() : null,
        'categorie': 'vie_paroisse',
      }).select('id').single();

      final id = result['id'];

      // Insérer les photos si pas de vidéo
      if (!_useVideo) {
        final photos = _photosCtrls
            .where((c) => c.text.trim().isNotEmpty)
            .toList();
        for (int i = 0; i < photos.length; i++) {
          await supabase.from('actualite_photos').insert({
            'actualite_id': id,
            'url': photos[i].text.trim(),
            'ordre': i,
          });
        }
      }

      widget.onSaved();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication'), backgroundColor: AppColors.error),
        );
      }
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
            Text('Nouvel article', style: AppTextStyles.heading2),
            const SizedBox(height: 20),

            Text('TITRE', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            _field(_titreCtrl, 'Titre de l\'article'),

            const SizedBox(height: 14),
            Text('ARTICLE', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            _field(_articleCtrl, 'Contenu de l\'article…', maxLines: 5),

            const SizedBox(height: 14),
            // Toggle À la une
            GestureDetector(
              onTap: () => setState(() => _aLaUne = !_aLaUne),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _aLaUne ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _aLaUne ? AppColors.accent : AppColors.divider, width: 1.5),
                    ),
                    child: _aLaUne ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 10),
                  Text('Mettre à la une', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Toggle photo / vidéo
            Row(
              children: [
                _modeChip('Photos (max 10)', !_useVideo, () => setState(() { _useVideo = false; })),
                const SizedBox(width: 10),
                _modeChip('Vidéo (1 URL)', _useVideo, () => setState(() { _useVideo = true; })),
              ],
            ),

            const SizedBox(height: 14),

            if (_useVideo) ...[
              Text('URL VIDÉO (YouTube / Vimeo)', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 6),
              _field(_videoCtrl, 'https://youtube.com/watch?v=…'),
            ] else ...[
              Text('PHOTOS (URL par ligne)', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 6),
              ..._photosCtrls.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('${e.key + 1}',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _field(e.value, 'https://…')),
                    if (e.key > 0)
                      GestureDetector(
                        onTap: () => setState(() => _photosCtrls.removeAt(e.key)),
                        child: const Padding(padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20)),
                      ),
                  ],
                ),
              )),
              if (_photosCtrls.length < 10)
                GestureDetector(
                  onTap: () => setState(() => _photosCtrls.add(TextEditingController())),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline, size: 18, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text('Ajouter une photo', style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('PUBLIER L\'ARTICLE', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.ink : AppColors.divider),
        ),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.textSecondary)),
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
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
