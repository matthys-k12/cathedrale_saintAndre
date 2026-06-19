// ⚠️ IMPORTANT : remplacer par l'URL réelle de votre backoffice déployé
// Exemple Vercel : 'https://backoffice-saint-andre.vercel.app'
// Exemple Netlify : 'https://saintandre-admin.netlify.app'
const String _kBase = 'https://backofficesaint-andr-4jn3.vercel.app';

// Génère un lien de partage cliquable dans WhatsApp (HTTPS)
String partageActualite(String id)   => '$_kBase/s/actualites/$id';
String partageAnnonce(String id)     => '$_kBase/s/annonces/$id';
String get partageSaintJour          => '$_kBase/s/saint-du-jour';
String get partageTexteJour          => '$_kBase/s/texte-du-jour';
String get partageApp                => '$_kBase/s/app';
