// Player audio intégré — boutons play/pause, avance/recul 15s,
// barre de progression cliquable, affichage du temps
// Utilise le package just_audio

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../cores/constants/app_colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String titre;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.titre,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final _seekBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);

      // Écouter les changements de durée
      _player.durationStream.listen((d) {
        if (mounted && d != null) {
          setState(() => _duration = d);
        }
      });

      // Écouter la position en temps réel
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      // Écouter l'état de lecture
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // Formater mm:ss
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inSeconds > 0
        ? _position.inSeconds / _duration.inSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // Label "EN COURS DE LECTURE"
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _isPlaying ? AppColors.orange : AppColors.divider,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isPlaying ? 'EN COURS DE LECTURE' : 'EN PAUSE',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _isPlaying
                      ? AppColors.orange
                      : AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barre de progression cliquable
          GestureDetector(
            key: _seekBarKey,
            onTapDown: (details) {
              final box = _seekBarKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              final pct = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
              _player.seek(_duration * pct);
            },
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_position),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _fmt(_duration),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Recul 15 secondes
              GestureDetector(
                onTap: () {
                  final newPos = _position - const Duration(seconds: 15);
                  _player.seek(
                    newPos < Duration.zero ? Duration.zero : newPos,
                  );
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.replay_rounded,
                        size: 22,
                        color: AppColors.textSubtitle,
                      ),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          '15',
                          style: GoogleFonts.dmSans(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Bouton Play/Pause principal
              GestureDetector(
                onTap: () async {
                  if (_isPlaying) {
                    await _player.pause();
                  } else {
                    await _player.play();
                  }
                },
                child: Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),

              const SizedBox(width: 20),

              // Avance 15 secondes
              GestureDetector(
                onTap: () {
                  final newPos = _position + const Duration(seconds: 15);
                  _player.seek(
                    newPos > _duration ? _duration : newPos,
                  );
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.forward_rounded,
                        size: 22,
                        color: AppColors.textSubtitle,
                      ),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          '15',
                          style: GoogleFonts.dmSans(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}