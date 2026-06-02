import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/tts_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  final String fallbackText;
  final String languageCode;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.fallbackText,
    required this.languageCode,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
      // Reset button state when playback completes
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        // Play from network URL
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
      } else {
        // Fallback to TTS
        TtsService()
            .speak(widget.fallbackText, languageCode: widget.languageCode);
      }
    } catch (e) {
      // Fallback to TTS if network play fails
      TtsService()
          .speak(widget.fallbackText, languageCode: widget.languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPlaying ? Colors.orange : AppColors.primaryPink,
        ),
        child: const Center(
          child: Text(
            '🔊',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
