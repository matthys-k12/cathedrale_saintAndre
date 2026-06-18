import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://trlaopqecmhwuarhyyle.supabase.co';
  // ⚠️ Remplacer par la clé "anon public" depuis Supabase → Settings → API
  // Ne jamais utiliser la service_role key ici
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRybGFvcHFlY21od3Vhcmh5eWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NDExOTgsImV4cCI6MjA5MTIxNzE5OH0.mA-6veAJQ3jcIP5F6cSDzDvHfqXLioh-IGjszydHwx8';


  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

final supabase = Supabase.instance.client;