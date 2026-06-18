import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/supabase/supabase_client.dart';
import '../../auth/screens/login_screen.dart';
import '../../../navigation/main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _kSeen = 'onboarding_seen';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeen, true);
    if (!mounted) return;
    final session = supabase.auth.currentSession;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => session != null ? const MainNavigation() : const LoginScreen(),
      ),
    );
  }

  void _next() {
    if (_page < _kSlides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _page == _kSlides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Slides occupent tout l'espace disponible
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _kSlides.length,
                itemBuilder: (_, i) => _SlideView(
                  data: _kSlides[i],
                  screenSize: size,
                ),
              ),
            ),

            // Barre de navigation bottom : dots + bouton
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots indicateurs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_kSlides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _kSlides[_page].blobColor
                              : const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  if (isLast)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Continuer',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _finish,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Passer cette étape',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: Colors.black45,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black45,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Données des slides ──────────────────────────────────────────────────

class _Slide {
  final Color blobColor;
  final String title;
  final String description;
  final IconData badge1;
  final IconData badge2;
  final int index;

  const _Slide({
    required this.blobColor,
    required this.title,
    required this.description,
    required this.badge1,
    required this.badge2,
    required this.index,
  });
}

const _kSlides = [
  _Slide(
    blobColor: AppColors.primary,
    title: 'Messes & Sacrements',
    description: 'Horaires de messe, demandes d\'intentions\net informations sur les célébrations\nde votre paroisse.',
    badge1: Icons.calendar_today_rounded,
    badge2: Icons.church_rounded,
    index: 0,
  ),
  _Slide(
    blobColor: AppColors.bleuMarial,
    title: 'Vie Spirituelle Quotidienne',
    description: 'Saint du jour, texte de la liturgie\net homélies en podcast pour nourrir\nvotre foi au quotidien.',
    badge1: Icons.headphones_rounded,
    badge2: Icons.menu_book_outlined,
    index: 1,
  ),
  _Slide(
    blobColor: AppColors.colorDons,
    title: 'Soutenez votre Cathédrale',
    description: 'Participez à la construction de la\nCathédrale, au Denier du Culte\net aux différentes campagnes.',
    badge1: Icons.favorite_rounded,
    badge2: Icons.volunteer_activism_outlined,
    index: 2,
  ),
  _Slide(
    blobColor: AppColors.orange,
    title: 'Restez connecté à votre\ncommunauté',
    description: 'Toutes les annonces paroissiales,\nles actualités et les événements\nde Saint André Yopougon.',
    badge1: Icons.notifications_rounded,
    badge2: Icons.campaign_rounded,
    index: 3,
  ),
];

// ── Vue d'un slide ──────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide data;
  final Size screenSize;

  const _SlideView({required this.data, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final blobSize = screenSize.width * 0.8;

    return Column(
      children: [
        // Zone du haut : blob + téléphone + badges flottants
        SizedBox(
          height: screenSize.height * 0.50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Blob coloré en arrière-plan (coin haut-gauche)
              Positioned(
                top: -(blobSize * 0.18),
                left: -(blobSize * 0.12),
                child: Container(
                  width: blobSize,
                  height: blobSize * 1.05,
                  decoration: BoxDecoration(
                    color: data.blobColor,
                    borderRadius: BorderRadius.circular(blobSize * 0.5),
                  ),
                ),
              ),

              // Accent vertical à droite (comme dans Prions en Église)
              Positioned(
                top: screenSize.height * 0.06,
                right: 16,
                child: Column(
                  children: [
                    Container(
                      width: 5, height: 40,
                      decoration: BoxDecoration(
                        color: data.blobColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 5, height: 18,
                      decoration: BoxDecoration(
                        color: data.blobColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),

              // Maquette téléphone centrée
              Center(
                child: _PhoneMockup(slideIndex: data.index, color: data.blobColor),
              ),

              // Badge flottant haut-droite (fond noir, comme dans Prions)
              Positioned(
                top: screenSize.height * 0.07,
                right: 28,
                child: _Badge(
                  icon: data.badge1,
                  bgColor: Colors.black,
                  size: 50,
                ),
              ),

              // Badge flottant bas-gauche (couleur du slide)
              Positioned(
                bottom: 14,
                left: 20,
                child: _Badge(
                  icon: data.badge2,
                  bgColor: data.blobColor,
                  size: 54,
                ),
              ),
            ],
          ),
        ),

        // Zone du bas : titre + description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14.5,
                  color: Colors.black54,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Badge flottant circulaire ───────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final double size;

  const _Badge({required this.icon, required this.bgColor, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.44),
    );
  }
}

// ── Maquette téléphone ──────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  final int slideIndex;
  final Color color;

  const _PhoneMockup({required this.slideIndex, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      height: 310,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (slideIndex) {
      case 0: return _MesseMockContent(color: color);
      case 1: return _SpirituelMockContent(color: color);
      case 2: return _DonsMockContent(color: color);
      default: return _AnnoncesMockContent(color: color);
    }
  }
}

// ── Contenu mock : Messe ────────────────────────────────────────────────

class _MesseMockContent extends StatelessWidget {
  final Color color;
  const _MesseMockContent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.church_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              _mockText('Messe du dimanche', Colors.white, 11, bold: true),
            ],
          ),
        ),
        // Logo / titre mini
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: _mockText('Saint André\nYopougon', Colors.black87, 12, bold: true),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 8),
        // Horaires
        ...[
          ('07h30', 'Messe du matin'),
          ('10h00', 'Grande messe'),
          ('18h00', 'Messe du soir'),
        ].map((h) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _mockText(h.$1, color, 10, bold: true),
              ),
              const SizedBox(width: 8),
              _mockText(h.$2, Colors.black54, 10),
            ],
          ),
        )),
        const Spacer(),
        // Bouton
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: _mockText('Demander une intention', Colors.white, 9, bold: true)),
          ),
        ),
      ],
    );
  }
}

// ── Contenu mock : Vie Spirituelle ──────────────────────────────────────

class _SpirituelMockContent extends StatelessWidget {
  final Color color;
  const _SpirituelMockContent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              _mockText('Vie Spirituelle', Colors.white, 11, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Saint du jour
        _MiniCard(
          icon: Icons.person_pin_outlined,
          color: color,
          label: 'Saint du jour',
          value: 'Saint Jean de Sahagún',
        ),
        const SizedBox(height: 6),
        // Texte du jour
        _MiniCard(
          icon: Icons.book_outlined,
          color: AppColors.navy,
          label: 'Texte du jour',
          value: '"Je suis le chemin,\nla vérité et la vie"',
        ),
        const SizedBox(height: 6),
        // Podcast
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.podcasts_rounded, color: AppColors.orange, size: 14),
                const SizedBox(width: 8),
                Expanded(child: _mockText('Homélie du dimanche', Colors.black87, 9, bold: true)),
                Icon(Icons.play_circle_rounded, color: AppColors.orange, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Contenu mock : Dons ─────────────────────────────────────────────────

class _DonsMockContent extends StatelessWidget {
  final Color color;
  const _DonsMockContent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.favorite_outline_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              _mockText('Dons & Denier du Culte', Colors.white, 10, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mockText('Construction de la Cathédrale', Colors.black87, 10, bold: true),
              const SizedBox(height: 6),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 0.02,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8E8E8),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _mockText('46 000 FCFA', Colors.black87, 8, bold: true),
                  _mockText('Objectif : 50M', Colors.black38, 8),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism_outlined, color: color, size: 14),
                const SizedBox(width: 6),
                Expanded(child: _mockText('Secours Catholique', Colors.black87, 9, bold: true)),
                _mockText('30 000 FCFA', color, 8, bold: true),
              ],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: _mockText('Contribuer maintenant', Colors.white, 9, bold: true)),
          ),
        ),
      ],
    );
  }
}

// ── Contenu mock : Annonces ─────────────────────────────────────────────

class _AnnoncesMockContent extends StatelessWidget {
  final Color color;
  const _AnnoncesMockContent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                _mockText('Annonces paroissiales', Colors.white, 10, bold: true),
              ]),
              const Icon(Icons.notifications_outlined, color: Colors.white, size: 14),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...[
          ('Activités', Color(0xFF7B1E3A), 'Grande fête de la paroisse\nle 24 juin prochain'),
          ('Mariage', Color(0xFFC9922A), 'Proclamation des bans\nde la famille Kouamé'),
          ('Prières', Color(0xFF1D9E75), 'Chapelet communautaire\nchaque vendredi 18h30'),
        ].map((item) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 7),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.$2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _mockText(item.$1, Colors.white, 7, bold: true),
                ),
                const SizedBox(width: 7),
                Expanded(child: _mockText(item.$3, Colors.black87, 8)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

// ── Mini card réutilisable ──────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _mockText(label, color, 8, bold: true),
                  _mockText(value, Colors.black54, 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper texte miniature ──────────────────────────────────────────────

Widget _mockText(String text, Color color, double size, {bool bold = false}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: 1.3,
    ),
  );
}
