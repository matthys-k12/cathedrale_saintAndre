import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../navigation/deep_link_service.dart';
import '../supabase/supabase_client.dart';

// ── Handler background (fonction top-level obligatoire) ───────────────
// Exécuté dans un isolate séparé quand l'app est fermée ou en arrière-plan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase déjà initialisé par l'OS — rien à faire ici
}

// ── Service principal ─────────────────────────────────────────────────
class NotificationService {
  static final _messaging   = FirebaseMessaging.instance;
  static final _localNotif  = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'saintandre_channel';
  static const _channelName = 'Cathédrale Saint André';
  static const _channelDesc = 'Annonces, actualités et contenus spirituels';

  static Future<void> init() async {
    // 1. Demander la permission (Android 13+ + iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Créer le canal Android (obligatoire depuis Android 8)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Initialiser flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) _handlePayload(details.payload!);
      },
    );

    // 4. Foreground — FCM ne montre rien par défaut, on le fait nous-mêmes
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 5. Background → l'utilisateur tape sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _handleNavigation(msg.data),
    );

    // 6. App fermée → l'utilisateur tape sur la notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(
        const Duration(milliseconds: 800),
        () => _handleNavigation(initial.data),
      );
    }

    // 7. Sauvegarder le token FCM dans Supabase
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // 8. Rafraîchir le token si FCM le regénère
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  // ── Enregistrer le token dans profiles ──────────────────────────────
  static Future<void> _saveToken(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (_) {}
  }

  // ── Afficher une notification locale (app ouverte) ───────────────────
  static void _showLocalNotification(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF8B1A2E),
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  // ── Encoder/décoder le payload pour la navigation ────────────────────
  static String _encodePayload(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final id   = data['id']   ?? '';
    return '$type|$id';
  }

  static void _handlePayload(String payload) {
    final parts = payload.split('|');
    _handleNavigation({
      'type': parts[0],
      'id':   parts.length > 1 ? parts[1] : '',
    });
  }

  // ── Naviguer vers le bon écran selon le type de contenu ─────────────
  static void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final id   = data['id']   ?? '';

    Uri? uri;
    switch (type) {
      case 'actualite':
        if (id.isNotEmpty) uri = Uri.parse('saintandre://actualites/$id');
        break;
      case 'annonce':
        uri = Uri.parse('saintandre://annonces');
        break;
      case 'saint_jour':
        uri = Uri.parse('saintandre://saint-du-jour');
        break;
      case 'texte_jour':
        uri = Uri.parse('saintandre://texte-du-jour');
        break;
      default:
        uri = Uri.parse('saintandre://annonces');
    }

    if (uri != null) DeepLinkService.navigateTo(uri);
  }
}
