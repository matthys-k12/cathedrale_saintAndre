// Point d'entrée de l'app.
// Flutter commence TOUJOURS par ce fichier.
// On initialise Supabase ici avant de lancer quoi que ce soit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'cores/supabase/supabase_client.dart';

void main() async {
  // OBLIGATOIRE avant tout appel async dans main()
  // Flutter doit initialiser ses bindings internes d'abord
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase avant de lancer l'interface
  await SupabaseConfig.initialize();

  // ProviderScope est le conteneur global de Riverpod
  // Il doit envelopper TOUTE l'app
  runApp(
    const ProviderScope(
      child: CathedralApp(),
    ),
  );
}