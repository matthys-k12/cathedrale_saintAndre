// Écran de connexion — fidèle à la maquette :
// - Photo de la cathédrale en hero avec overlay foncé
// - Titre "Heureux de vous revoir" en bordeaux serif
// - Citation en italique avec barre bordeaux à gauche
// - Champs avec icônes (téléphone, cadenas)
// - Bouton bordeaux plein "SE CONNECTER"

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = false;

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

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

  void _showMotDePasseOublie(BuildContext context) {
    final phoneCtrl = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Mot de passe oublié', style: AppTextStyles.heading2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez votre numéro de téléphone. Un lien de réinitialisation vous sera envoyé.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '07 00 00 00 00',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final phone = phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-\.]'), '');
                      if (phone.isEmpty) return;
                      setSt(() => sending = true);
                      try {
                        final email = 'user_$phone@gmail.com';
                        await supabase.auth.resetPasswordForEmail(email);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showError('Si ce numéro existe, un lien a été envoyé. Contactez la paroisse si besoin.');
                      } catch (_) {
                        setSt(() => sending = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showError('Contactez l\'administration de la paroisse pour réinitialiser votre mot de passe.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Envoyer', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
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
            child: Image.asset(
              'assets/images/Vitrail calices.png',
              fit: BoxFit.cover,
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
                  // Logo centré sur le fond de la photo
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primary,
                                  child: const Icon(Icons.church_rounded, color: Colors.white, size: 36),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Saint André',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            // Kicker paroisse — DM Sans rouge
                          Text(
                            'SAINT ANDRÉ · YOPOUGON',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Titre principal — Playfair Display serif
                          Text(
                            'Heureux de\nvous revoir.',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Citation avec barre rouge à gauche — signature éditoriale
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                            ),
                            child: Text(
                              '"Que la paix du Seigneur soit toujours avec vous."',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textBody,
                                height: 1.5,
                              ),
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

                          // "Se souvenir de moi" + "Mot de passe oublié ?" sur la même ligne
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(color: AppColors.divider, width: 1.5),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Se souvenir de moi',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _showMotDePasseOublie(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Bouton principal "SE CONNECTER" — rouge pill
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
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