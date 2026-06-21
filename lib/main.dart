// Point d'entrée de l'app.
// Flutter commence TOUJOURS par ce fichier.
// On initialise Supabase ici avant de lancer quoi que ce soit.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'cores/navigation/deep_link_service.dart';
import 'cores/notifications/notification_service.dart';
import 'cores/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Firebase — doit être initialisé avant le background handler
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Supabase
  await SupabaseConfig.initialize();

  // Deep links (saintandre://)
  DeepLinkService.init();

  // Notifications push (permission + canal + listeners)
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: CathedralApp(),
    ),
  );
}