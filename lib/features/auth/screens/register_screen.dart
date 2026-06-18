// Écran d'inscription amélioré :
// - Background image de cathédrale avec overlay
// - Vrai logo de la cathédrale Saint André
// - Carte blanche avec formulaire (comme le login)
// - Message CGU en bas "En cliquant sur S'inscrire, j'accepte..."
// - Stepper 3 étapes conservé
// - Tout le reste (logique, champs, validation) inchangé

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';
import '../../../navigation/main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomPrenomsController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomPrenomsController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Même nettoyage qu'à la connexion — CRUCIAL pour la cohérence
      final phoneRaw = _telephoneController.text
          .trim()
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('.', '');

      final phone = '+225$phoneRaw';
      final email = 'user_$phoneRaw@gmail.com';
      final nomPrenoms = _nomPrenomsController.text.trim();

      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'nom': nomPrenoms,
          'telephone': phone,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Le trigger handle_new_user crée le profil automatiquement.
      // Aucune opération manuelle sur profiles nécessaire.

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } on AuthException catch (e) {
      _showError(
        e.message.contains('already')
            ? 'Ce numéro est déjà associé à un compte'
            : 'Erreur : ${e.message}',
      );
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── COUCHE 1 : Background image cathédrale ─────────────────
          // Prend TOUT l'écran en fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/Vitrail calices.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.primary),
            ),
          ),

          // ── COUCHE 2 : Overlay foncé sur le background ─────────────
          // Rend le fond plus sombre pour que la carte blanche ressorte
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.70),
                  ],
                ),
              ),
            ),
          ),

          // ── COUCHE 3 : Contenu principal ───────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Logo + Nom + Tagline ──────────────────────────
                  _buildLogoSection(),

                  const SizedBox(height: 28),

                  // ── Carte blanche avec formulaire ─────────────────
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section logo en haut (sur le fond sombre) ──────────────────────
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Vrai logo de la cathédrale
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Légère ombre pour faire ressortir le logo sur le fond
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpeg',
              fit: BoxFit.cover,
              // Fallback si l'image n'est pas trouvée
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary,
                child: const Icon(
                  Icons.church_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Nom "Saint André" en serif blanc
        Text(
          'Saint André',
          style: AppTextStyles.heading1.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),

        const SizedBox(height: 6),

        // Tagline en blanc semi-transparent
        Text(
          'Créez votre compte pour rester connecté à la vie de votre paroisse',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Carte blanche avec le formulaire d'inscription ─────────────────
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        // Coins arrondis en haut seulement — comme le login screen
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Titre "Créer votre compte" ─────────────────────────
            Text('Créer votre compte', style: AppTextStyles.heading2),

            const SizedBox(height: 20),

            const SizedBox(height: 8),

            // ── Champ Nom complet ──────────────────────────────────
            AuthTextField(
              label: 'Nom Complet',
              hint: 'Jean-Marie Kouassi',
              controller: _nomPrenomsController,
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom obligatoire';
                }
                if (value.trim().length < 3) return 'Nom trop court';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Champ Téléphone avec +225 ──────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUMÉRO DE TÉLÉPHONE',
                  style: AppTextStyles.fieldLabel,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Bloc +225
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '+225',
                          style: AppTextStyles.inputText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: '07 00 00 00 00',
                          hintStyle: AppTextStyles.inputHint,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Numéro obligatoire';
                          }
                          if (value.trim().length < 8) {
                            return 'Numéro invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Champ Mot de passe ─────────────────────────────────
            AuthTextField(
              label: 'Mot de passe',
              hint: '••••••••••••',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mot de passe obligatoire';
                }
                if (value.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Champ Confirmer mot de passe ───────────────────────
            AuthTextField(
              label: 'Confirmer le mot de passe',
              hint: '••••••••••••',
              controller: _confirmPasswordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ── Bouton S'INSCRIRE — rouge pill ────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("S'INSCRIRE", style: AppTextStyles.button),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.church,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Message CGU ────────────────────────────────────────
            // "En cliquant sur S'inscrire, j'accepte la politique
            // de confidentialité et les conditions..."
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '* En cliquant sur "S\'inscrire", j\'accepte la ',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                children: [
                  // Lien cliquable — bordeaux souligné
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // TODO : ouvrir la politique de confidentialité
                      },
                      child: Text(
                        'politique de confidentialité',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: ' et les ',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // TODO : ouvrir les CGV
                      },
                      child: Text(
                        'conditions générales de vente',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: ' et les ',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // TODO : ouvrir les CGU
                      },
                      child: Text(
                        'conditions générales d\'utilisation',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: ' de cette plateforme.',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Lien vers connexion ────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Déjà membre ? ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Connectez-vous',
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
    );
  }
}