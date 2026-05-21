// Écran de connexion — fidèle à la maquette :
// - Photo de la cathédrale en hero avec overlay foncé
// - Titre "Heureux de vous revoir" en bordeaux serif
// - Citation en italique avec barre bordeaux à gauche
// - Champs avec icônes (téléphone, cadenas)
// - Bouton bordeaux plein "SE CONNECTER"

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../../navigation/main_navigation.dart';
import '../widgets/auth_text_field.dart';
import 'register_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Nettoyer le numéro : supprimer espaces, tirets, tout sauf les chiffres
      final phoneRaw = _telephoneController.text
          .trim()
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('.', '');

      // Reconstruire exactement le même email que lors de l'inscription
      final email = 'user_$phoneRaw@gmail.com';

      await supabase.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } on AuthException catch (e) {
      // Afficher le vrai message Supabase pour déboguer
      _showError('Erreur : ${e.message}');
    } catch (e) {
      _showError('Erreur de connexion : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pas de backgroundColor ici — le Stack gère le fond
      body: Stack(
        children: [
          // ── COUCHE 1 : Photo de la cathédrale en hero ──────────────
          // On utilise une image réseau pour le prototype.
          // En prod, remplace par Image.asset('assets/images/cathedrale.jpg')
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // La photo occupe 42% de la hauteur de l'écran
            height: MediaQuery.of(context).size.height * 0.42,
            child: Image.network(
              // Image temporaire de cathédrale — remplace par ta vraie photo
              'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=800',
              fit: BoxFit.cover,
              // Placeholder bordeaux pendant le chargement
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(color: AppColors.primary);
              },
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.primary),
            ),
          ),

          // ── COUCHE 2 : Overlay dégradé sur la photo ────────────────
          // Crée la transition douce entre la photo et le fond blanc cassé
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15), // Léger au sommet
                    Colors.black.withOpacity(0.45), // Plus foncé en bas
                  ],
                ),
              ),
            ),
          ),

          // ── COUCHE 3 : Contenu scrollable ──────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Espace pour laisser respirer sous la photo
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                  ),

                  // ── Carte blanche avec le formulaire ──
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      // Coins arrondis en haut seulement — slide depuis le bas
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre principal en serif bordeaux
                          Text(
                            'Heureux de vous revoir',
                            style: AppTextStyles.heading1,
                          ),

                          const SizedBox(height: 20),

                          // ── Citation avec barre bordeaux à gauche ──
                          // Reproduit exactement le style de la maquette
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              // Barre bordeaux à gauche — l'élément signature
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.accent,
                                  width: 3.5,
                                ),
                              ),
                            ),
                            child: Text(
                              '"Que la paix du Seigneur soit toujours avec vous."',
                              style: AppTextStyles.quote,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Champ téléphone avec icône téléphone
                          AuthTextField(
                            label: 'Numéro de téléphone',
                            hint: '07 00 00 00 00',
                            controller: _telephoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Numéro obligatoire';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Champ mot de passe avec icône cadenas
                          AuthTextField(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe obligatoire';
                              }
                              return null;
                            },
                          ),

                          // "Mot de passe oublié ?" aligné à droite
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO V2 : reset mot de passe par SMS
                              },
                              child: Text(
                                'Mot de passe oublié ?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Bouton principal "SE CONNECTER"
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                  : Text(
                                      'SE CONNECTER',
                                      style: AppTextStyles.button,
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Lien vers inscription
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Pas encore membre ? ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'S\'inscrire',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}