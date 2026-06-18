// Module Demande de Messe — flow en 3 étapes dans un BottomSheet.
// 
// Un BottomSheet est un panneau qui glisse depuis le bas de l'écran.
// On le choisit plutôt qu'un écran plein parce que la maquette Stitch
// montre clairement un overlay par-dessus la home (avec le X de fermeture).
//
// STRUCTURE :
//   MesseBottomSheet        → le conteneur principal + logique de navigation
//   _StepChoixDemandeur     → Étape 1 : Pour moi / Pour un tiers / Anonymat
//   _StepDetailsIntention   → Étape 2 : Type + Date + Heure + Intention
//   _StepConfirmation       → Étape 3 : Récapitulatif + Paiement

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';

// Point d'entrée — pousse un écran plein écran
void showMesseBottomSheet(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const MesseBottomSheet(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Widget principal — gère la navigation entre les 3 étapes
// ─────────────────────────────────────────────────────────────────────
class MesseBottomSheet extends StatefulWidget {
  const MesseBottomSheet({super.key});

  @override
  State<MesseBottomSheet> createState() => _MesseBottomSheetState();
}

class _MesseBottomSheetState extends State<MesseBottomSheet> {
  // Étape courante : 0, 1, ou 2
  int _currentStep = 0;

  // ── Données collectées au fil des étapes ──────────────────────────
  // Ces valeurs sont remplies progressivement et envoyées à Supabase
  // à l'étape 3.

  String _typeDemandeur = ''; // 'pour_moi' | 'pour_tiers' | 'anonymat'
  String _nomTiers = '';       // Rempli si pour_tiers
  String _typeMesse = 'action_de_grace';
  DateTime _dateMesse = DateTime.now();
  String _heureMesse = '';
  String _intention = '';

  // Passer à l'étape suivante
  void _nextStep() => setState(() => _currentStep++);

  // Revenir à l'étape précédente
  void _previousStep() => setState(() => _currentStep--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // resizeToAvoidBottomInset pousse le contenu au-dessus du clavier
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête : retour + barres + fermer ────────────────
            _buildHeader(),

            // ── Contenu scrollable de l'étape courante ─────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── En-tête éditorial : retour (si step>0) + 3 barres + fermer ─────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Bouton retour (36×36) — visible seulement si pas étape 1
          GestureDetector(
            onTap: _currentStep > 0 ? _previousStep : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1),
                color: Colors.white,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: _currentStep > 0
                    ? AppColors.ink
                    : Colors.transparent,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 3 barres de progression centrées
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton fermer (36×36)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Retourne le widget de l'étape courante
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _StepChoixDemandeur(
          selectedType: _typeDemandeur,
          nomTiers: _nomTiers,
          onNext: (type, nomTiers) {
            setState(() {
              _typeDemandeur = type;
              _nomTiers = nomTiers;
            });
            _nextStep();
          },
        );
      case 1:
        return _StepDetailsIntention(
          typeDemandeur: _typeDemandeur,
          typeMesse: _typeMesse,
          dateMesse: _dateMesse,
          heureMesse: _heureMesse,
          intention: _intention,
          onNext: (type, date, heure, intention) {
            setState(() {
              _typeMesse = type;
              _dateMesse = date;
              _heureMesse = heure;
              _intention = intention;
            });
            _nextStep();
          },
          onBack: _previousStep,
        );
      case 2:
        return _StepConfirmation(
          typeDemandeur: _typeDemandeur,
          nomTiers: _nomTiers,
          typeMesse: _typeMesse,
          dateMesse: _dateMesse,
          heureMesse: _heureMesse,
          intention: _intention,
          onBack: _previousStep,
          onClose: () => Navigator.of(context).pop(),
        );
      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// ÉTAPE 1 — Choix du demandeur
// ─────────────────────────────────────────────────────────────────────
class _StepChoixDemandeur extends StatefulWidget {
  final String selectedType;
  final String nomTiers;
  // Callback appelé quand l'utilisateur clique "Continuer"
  // Retourne le type choisi et le nom du tiers si applicable
  final Function(String type, String nomTiers) onNext;

  const _StepChoixDemandeur({
    required this.selectedType,
    required this.nomTiers,
    required this.onNext,
  });

  @override
  State<_StepChoixDemandeur> createState() => _StepChoixDemandeurState();
}

class _StepChoixDemandeurState extends State<_StepChoixDemandeur> {
  late String _selected;
  late TextEditingController _nomTiersController;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedType;
    _nomTiersController = TextEditingController(text: widget.nomTiers);
  }

  @override
  void dispose() {
    _nomTiersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Titre de l'étape en serif bordeaux
        Text(
          'Pour qui demandez-\nvous cette messe ?',
          style: AppTextStyles.heading2,
        ),

        const SizedBox(height: 28),

        // ── Card "Pour moi" ──────────────────────────────────────────
        _DemandeurCard(
          icon: Icons.person_outline_rounded,
          title: 'Pour moi',
          subtitle: 'Confier vos intentions personnelles au Seigneur.',
          isSelected: _selected == 'pour_moi',
          onTap: () => setState(() => _selected = 'pour_moi'),
        ),

        const SizedBox(height: 12),

        // ── Card "Pour un tiers" ─────────────────────────────────────
        _DemandeurCard(
          icon: Icons.people_outline_rounded,
          title: 'Pour un tiers',
          subtitle: 'Famille, amis, défunts ou proches malades.',
          isSelected: _selected == 'pour_tiers',
          onTap: () => setState(() => _selected = 'pour_tiers'),
        ),

        // Champ nom du tiers — visible SEULEMENT si "pour_tiers" sélectionné
        // AnimatedSize anime l'apparition/disparition du champ
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _selected == 'pour_tiers'
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _nomTiersController,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Nom et prénoms du tiers',
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
                )
              : const SizedBox(),
        ),

        const SizedBox(height: 12),

        // ── Card "Anonymat" ──────────────────────────────────────────
        _DemandeurCard(
          icon: Icons.visibility_off_outlined,
          title: 'Anonymat',
          subtitle: 'Une intention portée en toute discrétion.',
          isSelected: _selected == 'anonymat',
          onTap: () => setState(() => _selected = 'anonymat'),
        ),

        const SizedBox(height: 32),

        // Bouton Continuer — désactivé si rien n'est sélectionné
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    // Validation : si "pour_tiers" le nom est obligatoire
                    if (_selected == 'pour_tiers' &&
                        _nomTiersController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer le nom du tiers'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    widget.onNext(_selected, _nomTiersController.text.trim());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.divider,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text('Continuer', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }
}

// Card sélectionnable pour le choix du demandeur
class _DemandeurCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _DemandeurCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Fond bordeaux si sélectionné, blanc sinon
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Cercle radio 22×22 — rouge avec check si sélectionné
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (isSelected ? AppColors.primary : AppColors.divider),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: AppColors.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ÉTAPE 2 — Détails de l'intention
// ─────────────────────────────────────────────────────────────────────
class _StepDetailsIntention extends StatefulWidget {
  final String typeDemandeur;
  final String typeMesse;
  final DateTime dateMesse;
  final String heureMesse;
  final String intention;
  final Function(String type, DateTime date, String heure, String intention)
      onNext;
  final VoidCallback onBack;

  const _StepDetailsIntention({
    required this.typeDemandeur,
    required this.typeMesse,
    required this.dateMesse,
    required this.heureMesse,
    required this.intention,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_StepDetailsIntention> createState() => _StepDetailsIntentionState();
}

class _StepDetailsIntentionState extends State<_StepDetailsIntention> {
  late String _typeMesse;
  late DateTime _selectedDate;
  late String _selectedHeure;
  late TextEditingController _intentionController;
  late TextEditingController _intentionSuffixController;

  // Types de messe — "repos de l'âme" uniquement pour tiers/anonymat
  List<Map<String, String>> get _typesMesse {
    final base = [
      {'value': 'action_de_grace', 'label': 'Messe d\'Action de Grâces'},
      {'value': 'assistance_protection', 'label': 'Aide, Assistance et Protection'},
    ];
    if (widget.typeDemandeur == 'pour_tiers' || widget.typeDemandeur == 'anonymat') {
      base.add({'value': 'repos_ame', 'label': 'Repos de l\'Âme'});
    }
    return base;
  }

  // Créneaux horaires — chargés depuis Supabase, fallback local par jour
  List<String> _horairesDisponibles = [];
  Map<String, int> _delaisParHeure = {};

  // Horaires officiels par jour de la semaine (fallback local)
  // weekday Dart : 1=Lundi, 2=Mardi, 3=Mercredi, 4=Jeudi,
  //               5=Vendredi, 6=Samedi, 7=Dimanche
  static const Map<int, List<String>> _horairesFallback = {
    1: ['06:30', '19:00'],                          // Lundi
    2: ['06:30', '12:30', '19:00'],                 // Mardi
    3: ['06:30'],                                   // Mercredi
    4: ['06:30', '12:30', '19:00'],                 // Jeudi
    5: ['06:30', '12:30', '19:00'],                 // Vendredi
    6: ['06:30', '19:00'],                          // Samedi
    7: ['06:30', '08:30', '10:30', '18:30'],        // Dimanche
  };

  @override
  void initState() {
    super.initState();
    _typeMesse = widget.typeMesse;
    _selectedDate = widget.dateMesse;
    _selectedHeure = widget.heureMesse;
    _intentionController = TextEditingController(text: widget.intention);
    _intentionSuffixController = TextEditingController();
    _intentionController.addListener(() => setState(() {}));
    _intentionSuffixController.addListener(() => setState(() {}));
    _applyFallbackHoraires(_selectedDate);
    _loadHoraires(_selectedDate);
  }

  @override
  void dispose() {
    _intentionController.dispose();
    _intentionSuffixController.dispose();
    super.dispose();
  }

  void _applyFallbackHoraires(DateTime date) {
    final horaires = _horairesFallback[date.weekday] ?? ['06:30'];
    setState(() {
      _horairesDisponibles = horaires;
      _delaisParHeure = {};
      if (!_horairesDisponibles.contains(_selectedHeure)) {
        _selectedHeure = _horairesDisponibles.isNotEmpty
            ? _horairesDisponibles.first
            : '';
      }
    });
  }

  // Requête par colonne "jour" (string "Lundi", "Mardi"…) — même colonne que le backoffice.
  // Si Supabase renvoie une liste vide (admin a supprimé les horaires), on vide le fallback.
  // Si erreur réseau, le fallback déjà appliqué reste en place.
  Future<void> _loadHoraires(DateTime date) async {
    const joursFr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final jourNom = joursFr[date.weekday - 1];

    try {
      final data = await supabase
          .from('messe_horaires')
          .select('heure, delai_minutes')
          .eq('jour', jourNom)
          .eq('est_actif', true)
          .order('heure');

      if (!mounted) return;
      setState(() {
        if (data.isEmpty) {
          _horairesDisponibles = [];
          _delaisParHeure = {};
          _selectedHeure = '';
        } else {
          _horairesDisponibles = data
              .map<String>((h) => h['heure'].toString().substring(0, 5))
              .toList();
          _delaisParHeure = {
            for (final h in data)
              h['heure'].toString().substring(0, 5): (h['delai_minutes'] as int?) ?? 120
          };
          if (!_horairesDisponibles.contains(_selectedHeure)) {
            _selectedHeure = _horairesDisponibles.isNotEmpty
                ? _horairesDisponibles.first
                : '';
          }
        }
      });
    } catch (_) {
      // Erreur réseau : le fallback local reste en place
    }
  }

  // Retourne true si ce créneau doit être grisé (trop proche de l'heure de la messe)
  bool _isGrise(String heure) {
    final now = DateTime.now();
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) return false;
    final parts = heure.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final messeDt = DateTime(now.year, now.month, now.day, h, m);
    final delai = _delaisParHeure[heure] ?? 120;
    return now.isAfter(messeDt.subtract(Duration(minutes: delai)));
  }

  bool get _isPrefixed =>
      _typeMesse == 'action_de_grace' ||
      _typeMesse == 'assistance_protection' ||
      _typeMesse == 'repos_ame';

  String get _prefixLabel {
    switch (_typeMesse) {
      case 'action_de_grace':       return "Messe d'action de grâce pour ";
      case 'assistance_protection': return "Aide, assistance et protection pour ";
      case 'repos_ame':             return "Repos de l'âme de ";
      default:                      return '';
    }
  }

  String get _hintSuffix {
    if (_typeMesse == 'repos_ame') return 'nom du défunt…';
    return 'prénom(s) ou nom…';
  }

  String get _fullIntention {
    if (_isPrefixed) {
      final suffix = _intentionSuffixController.text.trim();
      if (suffix.isEmpty) return '';
      return '$_prefixLabel$suffix';
    }
    return _intentionController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Text('Détails de l\'intention', style: AppTextStyles.heading2),

        const SizedBox(height: 24),

        // ── Dropdown Type de messe ───────────────────────────────────
        Text('Type de messe', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _typeMesse,
              isExpanded: true,
              style: AppTextStyles.inputText,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              items: _typesMesse.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _typeMesse = value);
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Calendrier horizontal ────────────────────────────────────
        Text('Date de la messe', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 12),
        _buildCalendar(),

        const SizedBox(height: 20),

        // ── Créneaux horaires ────────────────────────────────────────
        Text('Heure disponible', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 10),
        _buildHeuresPills(),

        const SizedBox(height: 20),

        // ── Champ intention (OBLIGATOIRE) ────────────────────────────
        Row(
          children: [
            Text('Votre intention', style: AppTextStyles.fieldLabel),
            Text(
              ' *',
              style: AppTextStyles.fieldLabel.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isPrefixed)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prefixLabel,
                  style: AppTextStyles.inputText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _intentionSuffixController,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: _hintSuffix,
                    hintStyle: AppTextStyles.inputHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ],
            ),
          )
        else
          TextField(
            controller: _intentionController,
            maxLines: 4,
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              hintText: 'Écrivez ici le nom ou l\'intention particulière...',
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
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

        const SizedBox(height: 32),

        // ── Boutons Retour + Continuer ───────────────────────────────
        Row(
          children: [
            // Bouton retour
            OutlinedButton(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: Text(
                'Retour',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Bouton continuer — désactivé si heure vide OU intention vide
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedHeure.isEmpty || _fullIntention.isEmpty
                    ? null
                    : () => widget.onNext(
                          _typeMesse,
                          _selectedDate,
                          _selectedHeure,
                          _fullIntention,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.divider,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Continuer', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Calendrier horizontal (7 jours visibles) ──────────────────────
  Widget _buildCalendar() {
    // Générer 14 jours à partir d'aujourd'hui
    final jours = List.generate(14, (i) {
      return DateTime.now().add(Duration(days: i));
    });

    // Noms des jours en français abrégés
    const nomsJours = ['LU', 'MA', 'ME', 'JE', 'VE', 'SA', 'DI'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mois et année + flèches navigation
        Row(
          children: [
            Text(
              _formatMoisAnnee(_selectedDate),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row des jours horizontalement scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: jours.map((jour) {
              final isSelected = jour.year == _selectedDate.year &&
                  jour.month == _selectedDate.month &&
                  jour.day == _selectedDate.day;

              // Index du jour dans la semaine (0=Lundi, 6=Dimanche)
              final nomJour = nomsJours[jour.weekday - 1];

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = jour);
                  // Appliquer le fallback immédiatement puis charger Supabase
                  _applyFallbackHoraires(jour);
                  _loadHoraires(jour);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 44,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nom du jour (LU, MA...)
                      Text(
                        nomJour,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Numéro du jour
                      Text(
                        '${jour.day}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Pills des créneaux horaires ────────────────────────────────────
  Widget _buildHeuresPills() {
    if (_horairesDisponibles.isEmpty) {
      return Text(
        'Aucun horaire disponible pour ce jour',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _horairesDisponibles.map((heure) {
        final isSelected = heure == _selectedHeure;
        final isGrise = _isGrise(heure);
        return GestureDetector(
          onTap: isGrise ? null : () => setState(() => _selectedHeure = heure),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isGrise
                  ? AppColors.divider
                  : (isSelected ? AppColors.primary : AppColors.surface),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGrise
                    ? AppColors.divider
                    : (isSelected ? AppColors.primary : AppColors.divider),
              ),
            ),
            child: Text(
              heure,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isGrise
                    ? AppColors.textSecondary
                    : (isSelected ? Colors.white : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Formater "Octobre 2024" depuis une DateTime
  String _formatMoisAnnee(DateTime date) {
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${mois[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────
// ÉTAPE 3 — Confirmation + Paiement
// ─────────────────────────────────────────────────────────────────────
class _StepConfirmation extends StatefulWidget {
  final String typeDemandeur;
  final String nomTiers;
  final String typeMesse;
  final DateTime dateMesse;
  final String heureMesse;
  final String intention;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _StepConfirmation({
    required this.typeDemandeur,
    required this.nomTiers,
    required this.typeMesse,
    required this.dateMesse,
    required this.heureMesse,
    required this.intention,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<_StepConfirmation> createState() => _StepConfirmationState();
}

class _StepConfirmationState extends State<_StepConfirmation> {
  // Opérateur de paiement sélectionné
  String _selectedPaiement = 'wave';
  bool _isLoading = false;

  // Montants fixes définis dans le cahier des charges
  static const int _montantMesse = 3000;
  static const int _fraisAdmin = 200;
  static const int _fraisMobileMoney = 30;
  static const int _total = _montantMesse + _fraisAdmin + _fraisMobileMoney;

  // Les 4 opérateurs de paiement
  final List<Map<String, dynamic>> _operateurs = [
    {'id': 'wave', 'label': 'Wave', 'color': const Color(0xFF1BA0F5)},
    {'id': 'orange', 'label': 'Orange\nMoney', 'color': const Color(0xFFFF6600)},
    {'id': 'mtn', 'label': 'MTN\nMoMo', 'color': const Color(0xFFFFCC00)},
    {'id': 'moov', 'label': 'Moov\nMoney', 'color': const Color(0xFF0066CC)},
  ];

  // Enregistrer la demande dans Supabase
  Future<void> _handlePaiement() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non connecté');

      // Insérer la demande de messe dans la table
      await supabase.from('messe_demandes').insert({
        'user_id': userId,
        'type_demandeur': widget.typeDemandeur,
        'nom_tiers': widget.nomTiers.isNotEmpty ? widget.nomTiers : null,
        'type_messe': widget.typeMesse,
        // Formater la date en YYYY-MM-DD pour PostgreSQL
        'date_messe':
            '${widget.dateMesse.year}-${widget.dateMesse.month.toString().padLeft(2, '0')}-${widget.dateMesse.day.toString().padLeft(2, '0')}',
        'heure_messe': '${widget.heureMesse}:00',
        'intention': widget.intention.isNotEmpty ? widget.intention : null,
        'montant': _montantMesse,
        'frais_plateforme': _fraisAdmin,
        'frais_mobile_money': _fraisMobileMoney,
        'statut': 'en_attente',
      });

      // TODO : intégrer le vrai SDK de paiement (CinetPay / FedaPay)
      // Pour l'instant on simule un paiement réussi

      if (mounted) {
        // Fermer le BottomSheet
        widget.onClose();

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Demande de messe envoyée avec succès !',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Label "RÉCAPITULATIF"
        Text('RÉCAPITULATIF', style: AppTextStyles.fieldLabel),

        const SizedBox(height: 8),

        // Titre "Confirmation" en serif bordeaux
        Text('Confirmation', style: AppTextStyles.heading2),

        const SizedBox(height: 20),

        // ── Card récapitulatif ───────────────────────────────────────
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
              // Titre + badge "MESSE VALIDÉE"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails de l\'offrande',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Badge vert "MESSE VALIDÉE"
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
                      'MESSE VALIDÉE',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // Lignes de détail des montants
              _buildLigneMontant('Offrande de Messe', '$_montantMesse FCFA'),
              const SizedBox(height: 8),
              _buildLigneMontant('Frais administratifs', '$_fraisAdmin FCFA'),
              const SizedBox(height: 8),
              _buildLigneMontant('Frais Mobile Money', '$_fraisMobileMoney FCFA'),

              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // Total Playfair 26px w800 rouge — style éditorial
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total à payer',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_total',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: ' FCFA',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Choix mode de paiement ───────────────────────────────────
        Text(
          'CHOISIR UN MODE DE PAIEMENT',
          style: AppTextStyles.fieldLabel,
        ),

        const SizedBox(height: 12),

        // Grille 2×2 des opérateurs — box initiale colorée 36×36
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _operateurs.map((op) {
            final isSelected = _selectedPaiement == op['id'];
            final color = op['color'] as Color;
            // Initiale de l'opérateur
            final initiale = (op['label'] as String).substring(0, 1);
            return GestureDetector(
              onTap: () => setState(() => _selectedPaiement = op['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Box initiale colorée 36×36
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          initiale,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Label
                    Expanded(
                      child: Text(
                        (op['label'] as String).replaceAll('\n', ' '),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        // ── Bouton PAYER MAINTENANT ──────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePaiement,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isLoading
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

        const SizedBox(height: 12),

        // Bouton retour discret
        Center(
          child: TextButton(
            onPressed: widget.onBack,
            child: Text(
              'Modifier ma demande',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Ligne montant : label à gauche, valeur à droite
  Widget _buildLigneMontant(String label, String valeur) {
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