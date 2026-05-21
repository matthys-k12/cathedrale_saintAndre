// La navigation principale avec la barre du bas (Bottom Navigation Bar).
// C'est l'écran "coque" qui contient tous les autres écrans.
// Quand l'utilisateur tape sur une icône en bas, on affiche l'écran correspondant.

import 'package:flutter/material.dart';
import '../cores/constants/app_colors.dart';
import '../cores/constants/app_texts_styles.dart';
import '../features/casuels/screens/casuels_screen.dart';
import '../features/annonces/screens/annonces_screen.dart';
import '../features/actualites/screens/actualites_screen.dart';
import '../features/accounts/screens/account_screen.dart';

// Import des 4 écrans principaux (on les créera dans les prochains modules)
// Pour l'instant on met des placeholders
import '../features/auth/screens/home_screen.dart';
//import '../features/annonces/screens/annonces_screen.dart';
//import '../features/actualites/screens/actualites_screen.dart';
//import '../features/account/screens/account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Index de l'onglet actuellement sélectionné (0 = Accueil par défaut)
  int _currentIndex = 0;

  // Liste des 4 écrans — l'index correspond à l'onglet
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnnoncesScreen(),
    const ActualitesScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      
      // IndexedStack garde tous les écrans en mémoire
      // (contrairement à afficher/détruire à chaque changement d'onglet)
      // Avantage : l'état de chaque écran est préservé quand on change d'onglet
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Légère ombre au-dessus de la barre
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          
          // "fixed" = tous les labels visibles en permanence
          type: BottomNavigationBarType.fixed,
          
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.fieldLabel.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.fieldLabel,
          elevation: 0,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded), // Icône pleine si actif
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign_rounded),
              label: 'Annonces',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper_rounded),
              label: 'Actualités',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Mon compte',
            ),
          ],
        ),
      ),
    );
  }
}