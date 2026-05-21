// Module Dons complet :
// - Campagne principale "Construction de la Cathédrale"
//   avec grande image + barre de progression + montants
// - Section "Don libre pour l'Église" — don sans affectation
// - Section "Autres intentions" — catégories de dons
// - Pills de montants rapides + champ montant libre
// - BottomSheet de confirmation + paiement (même style que Messe/Casuels)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class DonsScreen extends StatefulWidget {
  const DonsScreen({super.key});

  @override
  State<DonsScreen> createState() => _DonsScreenState();
}

class _DonsScreenState extends State<DonsScreen> {
  // Campagnes chargées depuis Supabase
  List<Map<String, dynamic>> _campagnes = [];
  bool _isLoading = true;

  // Campagne actuellement sélectionnée pour le don
  Map<String, dynamic>? _campagneSelectionnee;

  // Montant sélectionné (0 = non sélectionné)
  int _montantSelectionne = 0;

  // Montant libre saisi dans le champ texte
  final _montantLibreController = TextEditingController();

  // Message optionnel du donateur
  final _messageController = TextEditingController();

  // Montants rapides proposés
  final List<int> _montantsRapides = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _loadCampagnes();
  }

  @override
  void dispose() {
    _montantLibreController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCampagnes() async {
    try {
      final data = await supabase
          .from('don_campagnes')
          .select()
          .eq('est_actif', true)
          .order('ordre');

      if (mounted) {
        setState(() {
          _campagnes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Campagne principale de construction
  Map<String, dynamic>? get _campagneConstruction {
    try {
      return _campagnes.firstWhere((c) => c['type'] == 'construction');
    } catch (_) {
      return null;
    }
  }

  // Campagne "Don libre"
  Map<String, dynamic>? get _campagneLibre {
    try {
      return _campagnes.firstWhere((c) => c['type'] == 'libre');
    } catch (_) {
      return null;
    }
  }

  // Autres catégories (type = 'categorie')
  List<Map<String, dynamic>> get _autresCampagnes {
    return _campagnes.where((c) => c['type'] == 'categorie').toList();
  }

  // Montant effectif (pill ou champ libre)
  int get _montantEffectif {
    if (_montantSelectionne > 0) return _montantSelectionne;
    final libre = int.tryParse(_montantLibreController.text) ?? 0;
    return libre;
  }

  // Frais mobile money (1%)
  int get _fraisMobileMoney => (_montantEffectif * 0.01).round();

  // Total
  int get _total => _montantEffectif + 200 + _fraisMobileMoney;

  // Formater un montant
  String _fmt(int montant) {
    if (montant == 0) return '0 FCFA';
    final s = montant.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  // Pourcentage de progression
  double _progression(Map<String, dynamic> campagne) {
    final objectif = campagne['objectif'] as int;
    final collecte = campagne['montant_collecte'] as int;
    if (objectif == 0) return 0;
    return (collecte / objectif).clamp(0.0, 1.0);
  }

  // Ouvrir le BottomSheet pour une campagne
  void _ouvrirDon(Map<String, dynamic> campagne) {
    setState(() {
      _campagneSelectionnee = campagne;
      _montantSelectionne = 0;
      _montantLibreController.clear();
      _messageController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _DonSheet(
        campagne: campagne,
        montantsRapides: _montantsRapides,
        montantLibreController: _montantLibreController,
        messageController: _messageController,
        onMontantChanged: (m) => setState(() {
          _montantSelectionne = m;
          if (m > 0) _montantLibreController.clear();
        }),
        getMontantEffectif: () => _montantEffectif,
        getFrais: () => _fraisMobileMoney,
        getTotal: () => _total,
        onPayer: _handlePaiement,
        montantSelectionne: _montantSelectionne,
        fmt: _fmt,
      ),
    );
  }

  Future<void> _handlePaiement(String operateur) async {
    if (_montantEffectif < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Montant minimum : 100 FCFA'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non connecté');

      await supabase.from('dons').insert({
        'user_id': userId,
        'campagne_id': _campagneSelectionnee!['id'],
        'campagne_titre': _campagneSelectionnee!['titre'],
        'montant': _montantEffectif,
        'montant_libre': _montantSelectionne == 0,
        'frais_plateforme': 200,
        'frais_mobile_money': _fraisMobileMoney,
        'operateur_paiement': operateur,
        'message': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        'statut': 'en_attente',
      });

      // Mettre à jour le montant collecté localement (optimistic update)
      if (mounted) {
        setState(() {
          final idx = _campagnes.indexWhere(
              (c) => c['id'] == _campagneSelectionnee!['id']);
          if (idx != -1) {
            _campagnes[idx]['montant_collecte'] =
                (_campagnes[idx]['montant_collecte'] as int) +
                    _montantEffectif;
          }
        });

        Navigator.of(context).pop(); // Fermer le sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Don de ${_fmt(_montantEffectif)} effectué. Merci !',
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
            content: Text('Erreur lors du don. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Header ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dons & Denier du Culte',
                                  style: AppTextStyles.heading2),
                              const SizedBox(height: 4),
                              Text(
                                'Soutenez la mission de votre paroisse',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Campagne Construction (hero) ────────────
                        if (_campagneConstruction != null)
                          _buildCampagneHero(_campagneConstruction!),

                        const SizedBox(height: 16),

                        // ── Denier du Culte ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDenierCulteCard(),
                        ),

                        const SizedBox(height: 16),

                        // ── Autres dons ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildAutresDonsCard(),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Hero campagne construction ──────────────────────────────────────
  Widget _buildCampagneHero(Map<String, dynamic> campagne) {
    final pct = _progression(campagne);
    final collecte = campagne['montant_collecte'] as int;
    final objectif = campagne['objectif'] as int;
    final restant = objectif - collecte;

    return GestureDetector(
      onTap: () => _ouvrirDon(campagne),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.primary,
          // Image cathédrale en fond
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=800',
            ),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image zone avec overlay et titre
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campagne['titre'],
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        campagne['description'] ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Infos progression
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Labels objectif collecté et %
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OBJECTIF COLLECTÉ',
                        style: AppTextStyles.fieldLabel,
                      ),
                      Text(
                        '${(pct * 100).round()}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Barre de progression or
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Montants collecté / restant
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MONTANT REÇU',
                                style: AppTextStyles.fieldLabel),
                            Text(
                              _fmt(collecte),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('RESTANT',
                                style: AppTextStyles.fieldLabel),
                            Text(
                              _fmt(restant > 0 ? restant : 0),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bouton faire un don
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => _ouvrirDon(campagne),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Contribuer maintenant',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Denier du Culte ────────────────────────────────────────────
  Widget _buildDenierCulteCard() {
    return GestureDetector(
      onTap: _ouvrirDenierCulte,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Denier du Culte', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Participez au soutien de votre Église selon votre catégorie.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Autres dons ────────────────────────────────────────────────
  Widget _buildAutresDonsCard() {
    return GestureDetector(
      onTap: _ouvrirAutresDons,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.church_rounded, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Autres dons', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Faites un don libre pour la paroisse,\navec une intention de prière.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Ouvrir le BottomSheet Denier du Culte
  void _ouvrirDenierCulte() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppColors.background,
      builder: (_) => _DenierCulteSheet(onPayer: _handlePaiement, fmt: _fmt),
    );
  }

  // Ouvrir le BottomSheet Autres dons
  void _ouvrirAutresDons() {
    setState(() {
      _campagneSelectionnee = _campagneLibre ?? {'id': 'autres', 'titre': 'Autres dons', 'description': null};
      _montantSelectionne = 0;
      _montantLibreController.clear();
      _messageController.clear();
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppColors.background,
      builder: (_) => _DonSheet(
        campagne: _campagneSelectionnee!,
        montantsRapides: _montantsRapides,
        montantLibreController: _montantLibreController,
        messageController: _messageController,
        onMontantChanged: (m) => setState(() { _montantSelectionne = m; if (m > 0) _montantLibreController.clear(); }),
        getMontantEffectif: () => _montantEffectif,
        getFrais: () => _fraisMobileMoney,
        getTotal: () => _total,
        onPayer: _handlePaiement,
        montantSelectionne: _montantSelectionne,
        fmt: _fmt,
        showIntention: true,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────
// BottomSheet de don — montants + message + paiement
// ─────────────────────────────────────────────────────────────────────
class _DonSheet extends StatefulWidget {
  final Map<String, dynamic> campagne;
  final List<int> montantsRapides;
  final TextEditingController montantLibreController;
  final TextEditingController messageController;
  final Function(int) onMontantChanged;
  final int Function() getMontantEffectif;
  final int Function() getFrais;
  final int Function() getTotal;
  final Future<void> Function(String) onPayer;
  final int montantSelectionne;
  final String Function(int) fmt;
  final bool showIntention;

  const _DonSheet({
    required this.campagne,
    required this.montantsRapides,
    required this.montantLibreController,
    required this.messageController,
    required this.onMontantChanged,
    required this.getMontantEffectif,
    required this.getFrais,
    required this.getTotal,
    required this.onPayer,
    required this.montantSelectionne,
    required this.fmt,
    this.showIntention = false,
  });

  @override
  State<_DonSheet> createState() => _DonSheetState();
}

class _DonSheetState extends State<_DonSheet> {
  late int _montant;
  String _operateur = 'wave';
  bool _isPaying = false;

  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave', 'label': 'Wave', 'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange\nMoney', 'color': const Color(0xFFFF6600)},
    {'id': 'mtn', 'label': 'MTN\nMoMo', 'color': const Color(0xFFFFCC00)},
    {'id': 'moov', 'label': 'Moov\nMoney', 'color': const Color(0xFF0066CC)},
  ];

  @override
  void initState() {
    super.initState();
    _montant = widget.montantSelectionne;
  }

  int get _montantEffectif {
    if (_montant > 0) return _montant;
    return int.tryParse(widget.montantLibreController.text) ?? 0;
  }

  int get _frais => (_montantEffectif * 0.01).round();
  int get _total => _montantEffectif + 200 + _frais;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Poignée
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

              // Titre campagne
              Text(
                widget.campagne['titre'],
                style: AppTextStyles.heading2,
              ),

              if (widget.campagne['description'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.campagne['description'],
                  style: AppTextStyles.bodySmall,
                ),
              ],

              const SizedBox(height: 24),

              // Label montant
              Text('Choisir un montant', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 12),

              // Pills montants rapides
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.montantsRapides.map((m) {
                  final isSelected = _montant == m;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _montant = m;
                        widget.montantLibreController.clear();
                      });
                      widget.onMontantChanged(m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10,
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
                        widget.fmt(m),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Champ montant libre
              TextField(
                controller: widget.montantLibreController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.inputText,
                onChanged: (_) {
                  setState(() => _montant = 0);
                  widget.onMontantChanged(0);
                },
                decoration: InputDecoration(
                  hintText: 'Montant libre (F CFA)',
                  hintStyle: AppTextStyles.inputHint,
                  suffixText: 'SAISIR LIBREMENT',
                  suffixStyle: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.accent,
                    fontSize: 9,
                  ),
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

              const SizedBox(height: 16),

              // Intention de prière (facultatif) — visible si showIntention
              if (widget.showIntention) ...[
                Text('Intention de prière (facultatif)', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.messageController,
                  maxLines: 3,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre intention de prière...',
                    hintStyle: AppTextStyles.inputHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],

              // Récap montant (visible si montant > 0)
              if (_montantEffectif > 0) ...[
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
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
                      _ligneMontant('Don', widget.fmt(_montantEffectif)),
                      const SizedBox(height: 6),
                      _ligneMontant('Frais administratifs', '200 FCFA'),
                      const SizedBox(height: 6),
                      _ligneMontant('Frais Mobile Money', widget.fmt(_frais)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                          Text(
                            widget.fmt(_total),
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Opérateurs de paiement
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
                        height: 52,
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
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Bouton FAIRE UN DON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPaying || _montantEffectif < 100
                      ? null
                      : () async {
                          setState(() => _isPaying = true);
                          await widget.onPayer(_operateur);
                          if (mounted) setState(() => _isPaying = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isPaying
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5,
                          ),
                        )
                      : Text('FAIRE UN DON', style: AppTextStyles.button),
                ),
              ),

              // Message si montant insuffisant
              if (_montantEffectif < 100 && _montantEffectif > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Montant minimum : 100 FCFA',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _ligneMontant(String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(valeur, style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// BottomSheet Denier du Culte
// ─────────────────────────────────────────────────────────────────────
class _DenierCulteSheet extends StatefulWidget {
  final Future<void> Function(String operateur) onPayer;
  final String Function(int) fmt;

  const _DenierCulteSheet({required this.onPayer, required this.fmt});

  @override
  State<_DenierCulteSheet> createState() => _DenierCulteSheetState();
}

class _DenierCulteSheetState extends State<_DenierCulteSheet> {
  // Catégories et tarifs du Denier du Culte
  // montant == -1 signifie saisie libre (fonctionnaire)
  // montant == -2 signifie saisie objet + montant (autre)
  static const List<Map<String, dynamic>> _categories = [
    {'id': 'primaire',      'label': 'Élève du Primaire',                         'montant': 500},
    {'id': 'secondaire',    'label': 'Élève Secondaire / Étudiant',               'montant': 1000},
    {'id': 'sans_emploi',   'label': 'Sans emploi',                               'montant': 2000},
    {'id': 'menagere',      'label': 'Ménagère',                                  'montant': 2000},
    {'id': 'retraite',      'label': 'Les retraités',                             'montant': 3000},
    {'id': 'fonctionnaire', 'label': 'Fonctionnaire / Opérateur économique',      'montant': -1},
    {'id': 'autre',         'label': 'Autre paiement',                            'montant': -2},
  ];

  String _categorieSelectionnee = '';
  int _montantFixe = 0;
  final _montantLibreCtrl = TextEditingController();
  final _objetCtrl = TextEditingController();
  String _operateur = 'wave';
  bool _isPaying = false;

  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave',   'label': 'Wave',         'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange\nMoney','color': const Color(0xFFFF6600)},
    {'id': 'mtn',    'label': 'MTN\nMoMo',   'color': const Color(0xFFFFCC00)},
    {'id': 'moov',   'label': 'Moov\nMoney', 'color': const Color(0xFF0066CC)},
  ];

  @override
  void dispose() {
    _montantLibreCtrl.dispose();
    _objetCtrl.dispose();
    super.dispose();
  }

  int get _montantEffectif {
    if (_montantFixe > 0) return _montantFixe;
    return int.tryParse(_montantLibreCtrl.text) ?? 0;
  }

  bool get _peutValider {
    if (_categorieSelectionnee.isEmpty) return false;
    final cat = _categories.firstWhere((c) => c['id'] == _categorieSelectionnee);
    final m = cat['montant'] as int;
    if (m > 0) return true;
    if (m == -1) return _montantEffectif >= 100;
    if (m == -2) return _objetCtrl.text.trim().isNotEmpty && _montantEffectif >= 100;
    return false;
  }

  String _fmt(int v) => widget.fmt(v);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) {
        return SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              Text('Denier du Culte', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text('Sélectionnez votre catégorie', style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),

              // Liste des catégories
              ..._categories.map((cat) {
                final isSelected = _categorieSelectionnee == cat['id'];
                final montant = cat['montant'] as int;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _categorieSelectionnee = cat['id'];
                      _montantFixe = montant > 0 ? montant : 0;
                      _montantLibreCtrl.clear();
                      _objetCtrl.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(cat['label'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ))),
                        if (montant > 0)
                          Text(_fmt(montant),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.white.withOpacity(0.85) : AppColors.accent,
                              fontWeight: FontWeight.w700,
                            )),
                        if (montant < 0)
                          Icon(Icons.edit_outlined,
                            size: 16,
                            color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              }),

              // Champ montant libre — fonctionnaire
              if (_categorieSelectionnee == 'fonctionnaire') ...[
                const SizedBox(height: 8),
                Text('Montant (équivalent 1 journée de travail)', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _montantLibreCtrl,
                  builder: (_, __, ___) => TextField(
                    controller: _montantLibreCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Saisir le montant en FCFA',
                      hintStyle: AppTextStyles.inputHint,
                      suffixText: 'FCFA',
                      filled: true, fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],

              // Champs objet + montant — autre paiement
              if (_categorieSelectionnee == 'autre') ...[
                const SizedBox(height: 8),
                Text('Objet du paiement *', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 8),
                TextField(
                  controller: _objetCtrl,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Précisez l\'objet du don',
                    hintStyle: AppTextStyles.inputHint,
                    filled: true, fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Montant *', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _montantLibreCtrl,
                  builder: (_, __, ___) => TextField(
                    controller: _montantLibreCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Saisir le montant en FCFA',
                      hintStyle: AppTextStyles.inputHint,
                      suffixText: 'FCFA',
                      filled: true, fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Opérateurs
              Text('MODE DE PAIEMENT', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 10),
              Row(
                children: _operateurs.map((op) {
                  final isSel = _operateur == op['id'];
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _operateur = op['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSel ? (op['color'] as Color).withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? op['color'] as Color : AppColors.divider,
                          width: isSel ? 2 : 0.5,
                        ),
                      ),
                      child: Center(child: Text(op['label'], textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: op['color'] as Color, fontWeight: FontWeight.w700, fontSize: 10))),
                    ),
                  ));
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Bouton Valider
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: (!_peutValider || _isPaying) ? null : () async {
                    setState(() => _isPaying = true);
                    await widget.onPayer(_operateur);
                    if (mounted) setState(() => _isPaying = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isPaying
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('VALIDER MON DENIER', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}