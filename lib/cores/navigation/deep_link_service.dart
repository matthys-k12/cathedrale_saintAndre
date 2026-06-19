import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../features/actualites/screens/actualite_detail_screen.dart';
import '../../features/spirituel/screens/saint_jour_screen.dart';
import '../../features/spirituel/screens/text_jour_screen.dart';

// Clé de navigation globale — permet de naviguer depuis n'importe où
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription? _sub;

  // Appelé au démarrage — intercepte le lien initial + les liens futurs
  static Future<void> init() async {
    // Lien qui a lancé l'app depuis un état fermé
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _navigate(initial);
    } catch (_) {}

    // Liens reçus pendant que l'app est en arrière-plan
    _sub = _appLinks.uriLinkStream.listen(_navigate, onError: (_) {});
  }

  static void dispose() => _sub?.cancel();

  // saintandre://actualites/UUID  → ActualiteDetailScreen(id)
  // saintandre://saint-du-jour    → SaintJourScreen
  // saintandre://texte-du-jour    → TexteJourScreen
  static void _navigate(Uri uri) {
    if (uri.scheme != 'saintandre') return;
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      // App pas encore prête — retry dans 500ms
      Future.delayed(const Duration(milliseconds: 500), () => _navigate(uri));
      return;
    }

    Widget? screen;

    switch (uri.host) {
      case 'actualites':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (id != null) screen = ActualiteDetailScreen(actualiteId: id);
        break;
      case 'saint-du-jour':
        screen = const SaintJourScreen();
        break;
      case 'texte-du-jour':
        screen = const TexteJourScreen();
        break;
    }

    if (screen != null) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }
}
