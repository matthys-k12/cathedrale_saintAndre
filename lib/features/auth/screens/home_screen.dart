// Écran d'accueil — reproduit fidèlement la maquette Stitch.
// Cet écran est scrollable verticalement. Le carrousel,
// les sections "Aujourd'hui", "Services" et "Intention de prière"
// s'enchaînent du haut vers le bas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../notifications/screens/notifications_screen.dart';
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

  // Nombre de notifications non lues
  int _notifCount = 0;

  // Incrémenté au pull-to-refresh pour forcer le rebuild des widgets enfants
  int _refreshKey = 0;

  // Clé SharedPreferences pour la date de dernière lecture
  static const _prefKey = 'notifs_last_seen';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotifCount();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select('nom, prenoms')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userName = data['nom']?.toString().split(' ').first ?? 'Saint André';
        });
      }
    } catch (_) {}
  }

  // Compte les annonces publiées après la dernière lecture
  Future<void> _loadNotifCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenMs = prefs.getInt(_prefKey) ?? 0;
      final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

      final data = await supabase
          .from('annonces')
          .select('id')
          .gt('created_at', lastSeen.toIso8601String());

      if (mounted) setState(() => _notifCount = (data as List).length);
    } catch (_) {}
  }

  // Pull-to-refresh — recharge tout
  Future<void> _refresh() async {
    setState(() => _refreshKey++);
    await Future.wait([_loadUserProfile(), _loadNotifCount()]);
  }

  // Ouvre l'écran notifications et remet le compteur à zéro après lecture
  Future<void> _ouvrirNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // Recharger le compteur après retour (NotificationsScreen met à jour SharedPreferences)
    _loadNotifCount();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Icônes blanches : la barre de statut se fond dans le header navy
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              // ── Header fixe en haut ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // ── Contenu scrollable ───────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 16),

                    // Carrousel — key forcé le rebuild au refresh
                    EventCarousel(key: ValueKey(_refreshKey)),

                    const SizedBox(height: 24),

                    // Section "Aujourd'hui" — key force le rebuild au refresh
                    TodaySection(key: ValueKey('today_$_refreshKey')),

                    const SizedBox(height: 24),

                    const ServicesGrid(),

                    const SizedBox(height: 24),

                    const IntentionCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),   // Scaffold
    );   // AnnotatedRegion
  }

  // ── Widget Header — bloc marine éditorial ────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : icône croix + bouton cloche avec dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo cathédrale dans cercle
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),

              // Bouton cloche — badge dynamique selon _notifCount
              GestureDetector(
                onTap: _ouvrirNotifications,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Fond semi-transparent
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      // Badge rouge — visible seulement si notifs non lues
                      if (_notifCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.navy, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                _notifCount > 99 ? '99+' : '$_notifCount',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Ligne 2 : "Bonjour," + nom + paroisse
          Text(
            'Bonjour,',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha:0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _userName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paroisse Saint André · Yopougon',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha:0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}