// Champ de saisie réutilisable qui reproduit exactement
// le style de la maquette : fond clair, label en petites majuscules,
// icône à gauche, bordure bordeaux au focus.

import 'package:cathedrale_saint_andre/cores/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;          // true → affiche ●●●● avec œil pour révéler
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;     // Icône à gauche (téléphone, cadenas...)
  final Widget? prefixWidget;     // Widget custom (pour le +225)

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.prefixWidget,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  // Contrôle l'affichage du mot de passe (visible ou masqué)
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label en petites majuscules — ex: "NOM & PRÉNOMS"
        Text(
          widget.label.toUpperCase(),
          style: AppTextStyles.fieldLabel,
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: widget.controller,
          // Si c'est un mot de passe, on masque selon l'état _obscureText
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          style: AppTextStyles.inputText,
          validator: widget.validator,

          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.inputHint,

            // Fond gris clair comme dans la maquette
            filled: true,
            fillColor: AppColors.surface,

            // Icône à gauche si fournie
            prefixIcon: widget.prefixWidget ??
                (widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: AppColors.textSecondary,
                      )
                    : null),

            // Icône œil à droite pour les mots de passe
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () {
                      // Inverser la visibilité du mot de passe
                      setState(() => _obscureText = !_obscureText);
                    },
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,

            // Bordures
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
            focusedErrorBorder: OutlineInputBorder(
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
        ),
      ],
    );
  }
}