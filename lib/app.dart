// Configuration globale de l'app :
// thème, couleurs, typographie, et écran de démarrage.
// C'est ici qu'on décide si l'utilisateur voit le Login ou la Home.

import 'package:flutter/material.dart';
import 'cores/constants/app_colors.dart';
import 'cores/supabase/supabase_client.dart';
import 'features/auth/screens/login_screen.dart';
import 'navigation/main_navigation.dart';

class CathedralApp extends StatelessWidget {
  const CathedralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saint André Yopougon',

      // Cache le bandeau rouge "DEBUG" en haut à droite
      debugShowCheckedModeBanner: false,

      // Thème global — définit les couleurs par défaut
      // de tous les widgets Material (boutons, inputs, etc.)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,

        // Supprime l'élévation/ombre par défaut des AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),

      // Écran de démarrage :
      // Si une session Supabase existe → l'utilisateur est déjà connecté
      // → on va directement sur la Home sans passer par le Login
      home: _resolveStartScreen(),
    );
  }

  Widget _resolveStartScreen() {
    // currentSession est null si personne n'est connecté
    final session = supabase.auth.currentSession;

    if (session != null) {
      // Session active → directement sur l'app
      return const MainNavigation();
    } else {
      // Pas de session → écran de connexion
      return const LoginScreen();
    }
  }
}