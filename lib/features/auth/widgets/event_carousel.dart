// Carousel d'événements — card héro éditorial :
// fond sombre 240px, badge rouge solid, dégradé 0.15→0→0.75,
// titre Playfair 26px w700, indicateurs pills animés.
// Données chargées depuis Supabase (table carrousel_items, est_actif = true).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/supabase/supabase_client.dart';

class CarouselEvent {
  final String titre;
  final String? sousTitre;
  final String imageUrl;

  const CarouselEvent({
    required this.titre,
    this.sousTitre,
    required this.imageUrl,
  });

  factory CarouselEvent.fromJson(Map<String, dynamic> json) {
    return CarouselEvent(
      titre: json['titre'] as String? ?? '',
      sousTitre: json['sous_titre'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class EventCarousel extends StatefulWidget {
  const EventCarousel({super.key});

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  List<CarouselEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final data = await supabase
          .from('carrousel_items')
          .select('titre, sous_titre, image_url')
          .eq('est_actif', true)
          .order('ordre', ascending: true);

      if (mounted) {
        setState(() {
          _events = (data as List)
              .map((e) => CarouselEvent.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 240,
        child: PageView.builder(
          itemCount: 1,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.ink.withValues(alpha: 0.15),
            ),
          ),
        ),
      );
    }

    if (_events.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _events.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) => _buildHeroCard(_events[index]),
          ),
        ),

        if (_events.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_events.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroCard(CarouselEvent event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.ink,
        image: event.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(event.imageUrl),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.30, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.titre,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                if (event.sousTitre != null && event.sousTitre!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.sousTitre!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
