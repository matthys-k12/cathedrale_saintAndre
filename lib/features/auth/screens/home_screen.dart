// Écran d'accueil — reproduit fidèlement la maquette Stitch.
// Cet écran est scrollable verticalement. Le carrousel,
// les sections "Aujourd'hui", "Services" et "Intention de prière"
// s'enchaînent du haut vers le bas.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../widgets/event_carousel.dart';
import '../widgets/today_section.dart';
import '../widgets/services_grid.dart';
import '../widgets/intention_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Nom de l'utilisateur connecté — chargé depuis Supabase
  String _userName = 'Saint André';

  @override
  void initState() {
    super.initState();
    // Charger le profil de l'utilisateur dès l'ouverture de l'écran
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Récupérer l'ID de l'utilisateur connecté
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Lire son profil dans la table "profiles"
      final data = await supabase
          .from('profiles')
          .select('nom, prenoms')
          .eq('id', userId)
          .single(); // On attend un seul résultat

      if (mounted) {
        setState(() {
          // Afficher le prénom uniquement (premier mot du champ nom)
          _userName = data['nom']?.toString().split(' ').first ?? 'Saint André';
        });
      }
    } catch (_) {
      // En cas d'erreur réseau, on garde le nom par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: CustomScrollView(
          // CustomScrollView permet de mixer différents types de widgets
          // scrollables (SliverAppBar, SliverList, etc.)
          slivers: [

            // ── Header fixe en haut ────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // ── Contenu scrollable ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 16),

                  // Carrousel des événements paroissiaux
                  const EventCarousel(),

                  const SizedBox(height: 24),

                  // Section "Aujourd'hui" (Texte du jour + Saint du jour)
                  const TodaySection(),

                  const SizedBox(height: 24),

                  // Grille des services (Messe, Casuels, Don, Podcast)
                  const ServicesGrid(),

                  const SizedBox(height: 24),

                  // Card "Intention de prière" dorée
                  const IntentionCard(),

                  // Espace en bas pour que le dernier élément
                  // ne soit pas caché par la bottom nav
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Avatar rond avec initiales — comme dans la maquette
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              // Image de la cathédrale en avatar
              // En prod : remplace par une vraie photo de profil
              shape: BoxShape.circle,
              color: AppColors.primary,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=100',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Texte "Bonjour / Saint André"
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _userName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Pousse la cloche tout à droite
          const Spacer(),

          // Icône cloche notifications
          GestureDetector(
            onTap: () {
              // TODO : ouvrir les notifications
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}