// Configuration globale de l'app :
// thème, couleurs, typographie, et écran de démarrage.
// C'est ici qu'on décide si l'utilisateur voit le Login ou la Home.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cores/constants/app_colors.dart';
import 'cores/navigation/deep_link_service.dart';
import 'cores/supabase/supabase_client.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'navigation/main_navigation.dart';

class CathedralApp extends StatelessWidget {
  const CathedralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cathédrale St André',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _resolveStartScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Écran blanc pendant le chargement de SharedPreferences (~50ms)
            return const Scaffold(backgroundColor: Colors.white);
          }
          return snapshot.data!;
        },
      ),
    );
  }

  static Future<Widget> _resolveStartScreen() async {
    final prefs = await SharedPreferences.getInstance();

    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!seen) return const OnboardingScreen();

    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      try {
        // refreshSession() recharge la session depuis le stockage local,
        // et renouvelle via le refresh token si l'access token a expiré
        final res = await supabase.auth.refreshSession();
        if (res.session != null) return const MainNavigation();
      } catch (_) {
        // Session expirée ou réseau indisponible → retour login
      }
    }

    return const LoginScreen();
  }
}