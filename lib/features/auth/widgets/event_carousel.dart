//Carousel d'évènements paroissiaux 
//visibles sur la droite ppour inviter au scroll


import 'package:flutter/material.dart';
import '../../../cores/constants/app_colors.dart';
import '../../../cores/constants/app_texts_styles.dart';


//Modèle de données pour un évènement du Carrousel

class CarouselEvent {
  final String title;
  final String badge ; //"EVENEMENT, ANNONCE"
  final String imageUrl;

  const CarouselEvent({
    required this.title,
    required this.badge,
    required this.imageUrl
  });
}

class EventCarousel extends StatefulWidget {
  const EventCarousel ({super.key});

  @override
  State<EventCarousel> createState() => _EventCarouselState();

}

class _EventCarouselState extends State<EventCarousel> {
  // controleur pour tracker la page active 
  final PageController _pageController = PageController(
    // viewportFraction < 1 → la card suivante est partiellement visible
    // C'est ce qui crée l'effet "peek" visible dans la maquette

    viewportFraction: 0.88,
  );

  int _currentPage = 0;

  //Données fictives pour le prototype - en prod, elles viennent de supabase

  final List<CarouselEvent> _events = const [
    CarouselEvent(title: 'Kermesse Paroissiale', badge: 'EVENEMENT', imageUrl: 'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=600',),
    CarouselEvent(
      title: 'Retraite de Carême',
      badge: 'ANNONCE',
      imageUrl:
          'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=600',
    ),
    CarouselEvent(
      title: 'Célébration de Pâques',
      badge: 'ÉVÉNEMENT',
      imageUrl:
          'https://images.unsplash.com/photo-1604537466158-719b1972feb8?w=600',
    ),
  ];

  @override
  Widget build (BuildContext context) {
    return Column(
      children: [
        // carousel cards
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _events.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index){
              return _buildEventCard(_events[index]);
            },
          ),
        ),

        const SizedBox(height: 12),


        //indicateurs de pages (petits points )
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_events.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin : const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6, //le point actif s'élargit
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(3)
              ), 
            );
          }),
        )
      ],
    );
  }

  //Construction d'une carte d'un évènement
  Widget _buildEventCard(CarouselEvent event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Image en fond de la card
        image: DecorationImage(
          image: NetworkImage(event.imageUrl),
          fit: BoxFit.cover,
          // Placeholder en cas d'erreur réseau
          onError: (_, __) {},
        ),
        color: AppColors.primary, // Couleur de fallback
      ),
      child: Stack(
        children: [
          // Overlay dégradé du bas — rend le texte lisible sur l'image
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Contenu de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge en haut à gauche — "ÉVÉNEMENT"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // Fond semi-transparent blanc
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    event.badge,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                // Pousse le titre vers le bas
                const Spacer(),

                // Titre de l'événement en bas
                Text(
                  event.title,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}