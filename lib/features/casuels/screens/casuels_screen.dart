// Module Casuels complet :
// - Toggle Pour moi / Pour un tiers
// - 3 accordéons : Initiation / Mariage / Enterrement
// - Tarifs chargés dynamiquement depuis Supabase
// - Pills de sous-types sélectionnables
// - Récapitulatif + paiement (même style que Messe)

import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

class CasuelsScreen extends StatefulWidget {
  const CasuelsScreen({super.key});

  @override
  State<CasuelsScreen> createState() => _CasuelsScreenState();
}

class _CasuelsScreenState extends State<CasuelsScreen> {
  // ── État global ───────────────────────────────────────────────────
  String _typeDemandeur = 'pour_moi'; // 'pour_moi' | 'pour_tiers'
  String _nomBeneficiaire = '';

  // Catégorie ouverte dans l'accordéon ('initiation', 'mariage', 'enterrement', '')
  String _categorieOuverte = 'initiation';

  // Sous-type sélectionné (ex: 'bapteme_bebe')
  String _sousTypeSelectionne = '';

  // Tarif sélectionné complet
  Map<String, dynamic>? _tarifSelectionne;

  // Tous les tarifs chargés depuis Supabase
  List<Map<String, dynamic>> _tarifs = [];

  bool _isLoading = true;
  bool _isPaymentLoading = false;

  // Opérateur de paiement sélectionné
  String _operateurPaiement = 'wave';

  // Controller pour le nom du bénéficiaire
  final _nomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTarifs();
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  // Charger tous les tarifs depuis Supabase
  Future<void> _loadTarifs() async {
    try {
      final data = await supabase
          .from('casuel_tarifs')
          .select()
          .eq('est_actif', true)
          .order('categorie')
          .order('montant');

      if (mounted) {
        setState(() {
          _tarifs = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtrer les tarifs par catégorie
  List<Map<String, dynamic>> _tarifsByCategorie(String categorie) {
    return _tarifs.where((t) => t['categorie'] == categorie).toList();
  }

  // Calculer les frais mobile money (1% du montant)
  int get _fraisMobileMoney {
    if (_tarifSelectionne == null) return 0;
    return ((_tarifSelectionne!['montant'] as int) * 0.01).round();
  }

  int get _total {
    if (_tarifSelectionne == null) return 0;
    return (_tarifSelectionne!['montant'] as int) + 200 + _fraisMobileMoney;
  }

  // Soumettre le paiement
  Future<void> _handlePaiement() async {
    if (_tarifSelectionne == null) return;

    // Validation : nom bénéficiaire obligatoire si "pour un tiers"
    if (_typeDemandeur == 'pour_tiers' && _nomController.text.trim().isEmpty) {
      _showError('Veuillez entrer le nom du bénéficiaire');
      return;
    }

    setState(() => _isPaymentLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non connecté');

      await supabase.from('casuel_demandes').insert({
        'user_id': userId,
        'type_demandeur': _typeDemandeur,
        'nom_beneficiaire': _typeDemandeur == 'pour_tiers'
            ? _nomController.text.trim()
            : null,
        'categorie': _tarifSelectionne!['categorie'],
        'sous_type': _tarifSelectionne!['sous_type'],
        'label': _tarifSelectionne!['label'],
        'montant': _tarifSelectionne!['montant'],
        'frais_plateforme': 200,
        'frais_mobile_money': _fraisMobileMoney,
        'operateur_paiement': _operateurPaiement,
        'statut': 'en_attente',
      });

      if (mounted) {
        // Fermer le bottom sheet de paiement
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Demande de casuel envoyée avec succès !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Réinitialiser la sélection
        setState(() {
          _sousTypeSelectionne = '';
          _tarifSelectionne = null;
          _nomController.clear();
        });
      }
    } catch (e) {
      _showError('Erreur lors de l\'envoi. Réessayez.');
    } finally {
      if (mounted) setState(() => _isPaymentLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Ouvrir le bottom sheet de paiement
  void _showPaiementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (_) => _PaiementSheet(
        tarif: _tarifSelectionne!,
        fraisMobileMoney: _fraisMobileMoney,
        total: _total,
        operateurSelectionne: _operateurPaiement,
        isLoading: _isPaymentLoading,
        onOperateurChanged: (op) =>
            setState(() => _operateurPaiement = op),
        onPayer: _handlePaiement,
      ),
    );
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
                  // ── Header ────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Contenu ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Toggle Pour moi / Pour un tiers
                          _buildToggleDemandeur(),

                          // Champ nom bénéficiaire (visible si pour_tiers)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _typeDemandeur == 'pour_tiers'
                                ? _buildNomBeneficiaire()
                                : const SizedBox(),
                          ),

                          const SizedBox(height: 24),

                          // Accordéon Initiation
                          _buildAccordeon(
                            titre: 'Initiation',
                            categorie: 'initiation',
                          ),

                          const SizedBox(height: 12),

                          // Accordéon Mariage
                          _buildAccordeon(
                            titre: 'Mariage',
                            categorie: 'mariage',
                          ),

                          const SizedBox(height: 12),

                          // Accordéon Enterrement
                          _buildAccordeon(
                            titre: 'Enterrement',
                            categorie: 'enterrement',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),

      // ── Bouton Continuer fixe en bas ───────────────────────────────
      // Visible seulement quand un sous-type est sélectionné
      bottomNavigationBar: _tarifSelectionne != null
          ? _buildBottomBar()
          : const SizedBox(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paiement des casuels', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(
            'Soutenez la vie sacramentelle de votre paroisse',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  // ── Toggle Pour moi / Pour un tiers ───────────────────────────────
  Widget _buildToggleDemandeur() {
    // "Pour moi" est désactivé quand l'Enterrement est sélectionné
    final pourMoiDesactive = _categorieOuverte == 'enterrement';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Card "Pour moi"
            Expanded(
              child: GestureDetector(
                onTap: pourMoiDesactive
                    ? null // Désactivé pour l'enterrement
                    : () => setState(() => _typeDemandeur = 'pour_moi'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 90,
                  decoration: BoxDecoration(
                    color: pourMoiDesactive
                        ? AppColors.surface.withOpacity(0.5)
                        : _typeDemandeur == 'pour_moi'
                            ? AppColors.primary
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: pourMoiDesactive
                            ? AppColors.textSecondary.withOpacity(0.4)
                            : _typeDemandeur == 'pour_moi'
                                ? Colors.white
                                : AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pour moi',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: pourMoiDesactive
                              ? AppColors.textSecondary.withOpacity(0.4)
                              : _typeDemandeur == 'pour_moi'
                                  ? Colors.white
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Card "Pour un tiers"
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _typeDemandeur = 'pour_tiers'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 90,
                  decoration: BoxDecoration(
                    color: _typeDemandeur == 'pour_tiers'
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: _typeDemandeur == 'pour_tiers'
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pour un tiers',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _typeDemandeur == 'pour_tiers'
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Message d'information si Enterrement sélectionné
        if (pourMoiDesactive) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Le paiement d\'enterrement ne peut se faire que pour un tiers.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  // ── Champ nom bénéficiaire (pour un tiers) ────────────────────────
  Widget _buildNomBeneficiaire() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _nomController,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Nom et prénoms du bénéficiaire',
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
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
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ── Accordéon par catégorie ───────────────────────────────────────
  Widget _buildAccordeon({
    required String titre,
    required String categorie,
  }) {
    final isOuvert = _categorieOuverte == categorie;
    final tarifs = _tarifsByCategorie(categorie);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // Bordure or si cette catégorie a un sous-type sélectionné
          color: _tarifSelectionne != null &&
                  _tarifSelectionne!['categorie'] == categorie
              ? AppColors.accent
              : AppColors.divider,
          width: _tarifSelectionne != null &&
                  _tarifSelectionne!['categorie'] == categorie
              ? 1.5
              : 0.5,
        ),
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
          // ── En-tête de l'accordéon (cliquable) ──────────────────
          GestureDetector(
            onTap: () {
              setState(() {
                // Si déjà ouvert → fermer, sinon ouvrir
                _categorieOuverte = isOuvert ? '' : categorie;
                // Si on ouvre l'Enterrement avec "pour_moi" actif,
                // basculer automatiquement sur "pour_tiers"
                if (categorie == 'enterrement' &&
                    !isOuvert &&
                    _typeDemandeur == 'pour_moi') {
                  _typeDemandeur = 'pour_tiers';
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              color: Colors.transparent,
              child: Row(
                children: [
                  Text(
                    titre,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      // Titre en bordeaux si catégorie ouverte
                      color: isOuvert
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Flèche qui tourne selon l'état
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isOuvert ? 0 : 0.5,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: isOuvert
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu de l'accordéon (visible si ouvert) ──────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOuvert
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 14),

                        // Pills des sous-types
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tarifs.map((tarif) {
                            final isSelected =
                                _sousTypeSelectionne == tarif['sous_type'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sousTypeSelectionne = tarif['sous_type'];
                                  _tarifSelectionne = tarif;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  // Fond bordeaux si sélectionné
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Label du sous-type
                                    Text(
                                      tarif['label'],
                                      style:
                                          AppTextStyles.bodySmall.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Tarif affiché sous le label
                                    Text(
                                      _formatMontant(tarif['montant']),
                                      style:
                                          AppTextStyles.bodySmall.copyWith(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.85)
                                            : AppColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ── Barre du bas avec tarif + bouton Continuer ────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tarif sélectionné à gauche
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tarifSelectionne!['label'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatMontant(_tarifSelectionne!['montant']),
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Bouton Continuer
          Expanded(
            child: ElevatedButton(
              onPressed: _showPaiementSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('CONTINUER ›', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  // Formatter un montant en "5 000 FCFA"
  String _formatMontant(int montant) {
    final parts = montant.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(parts[i]);
    }
    return '${buffer.toString()} FCFA';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bottom Sheet de paiement — réutilise le même style que la Messe
// ─────────────────────────────────────────────────────────────────────
class _PaiementSheet extends StatefulWidget {
  final Map<String, dynamic> tarif;
  final int fraisMobileMoney;
  final int total;
  final String operateurSelectionne;
  final bool isLoading;
  final Function(String) onOperateurChanged;
  final VoidCallback onPayer;

  const _PaiementSheet({
    required this.tarif,
    required this.fraisMobileMoney,
    required this.total,
    required this.operateurSelectionne,
    required this.isLoading,
    required this.onOperateurChanged,
    required this.onPayer,
  });

  @override
  State<_PaiementSheet> createState() => _PaiementSheetState();
}

class _PaiementSheetState extends State<_PaiementSheet> {
  late String _operateur;

  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave', 'label': 'Wave', 'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange\nMoney', 'color': const Color(0xFFFF6600)},
    {'id': 'mtn', 'label': 'MTN\nMoMo', 'color': const Color(0xFFFFCC00)},
    {'id': 'moov', 'label': 'Moov\nMoney', 'color': const Color(0xFF0066CC)},
  ];

  @override
  void initState() {
    super.initState();
    _operateur = widget.operateurSelectionne;
  }

  String _formatMontant(int montant) {
    final parts = montant.toString().split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(parts[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée de drag en haut
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text('RÉCAPITULATIF', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 8),
              Text('Confirmation', style: AppTextStyles.heading2),

              const SizedBox(height: 20),

              // Card récapitulatif
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + badge validé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.tarif['label'],
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VALIDÉ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),

                    // Lignes montants
                    _ligne('Casuel', _formatMontant(widget.tarif['montant'])),
                    const SizedBox(height: 8),
                    _ligne('Frais administratifs', '200 FCFA'),
                    const SizedBox(height: 8),
                    _ligne(
                      'Frais Mobile Money',
                      _formatMontant(widget.fraisMobileMoney),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 16),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total à payer',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatMontant(widget.total),
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'CHOISIR UN MODE DE PAIEMENT',
                style: AppTextStyles.fieldLabel,
              ),

              const SizedBox(height: 12),

              // Grille opérateurs
              Row(
                children: _operateurs.map((op) {
                  final isSelected = _operateur == op['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _operateur = op['id']);
                        widget.onOperateurChanged(op['id']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        height: 56,
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

              const SizedBox(height: 28),

              // Bouton PAYER
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text('PAYER MAINTENANT', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ligne(String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          valeur,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
