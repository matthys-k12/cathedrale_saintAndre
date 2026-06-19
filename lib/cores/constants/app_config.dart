// ⚠️ IMPORTANT : remplacer par l'URL réelle de votre backoffice déployé
// Exemple Vercel : 'https://backoffice-saint-andre.vercel.app'
// Exemple Netlify : 'https://saintandre-admin.netlify.app'
const String kBackofficeUrl = 'https://VOTRE-BACKOFFICE-URL.vercel.app';

// Génère un lien de partage cliquable dans WhatsApp (HTTPS)
String partageActualite(String id)   => '$kBackofficeUrl/s/actualites/$id';
String get partageSaintJour          => '$kBackofficeUrl/s/saint-du-jour';
String get partageTexteJour          => '$kBackofficeUrl/s/texte-du-jour';
