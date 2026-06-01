import 'dart:async';
import 'dart:html' as html;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

/// Web-specific TTS service using the Web Speech API.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  /// Maximum retries while waiting for browser voices to load.
  static const int _maxVoiceRetries = 10;
  static const int _voiceRetryDelayMs = 100;

  bool get isSupported => html.window.speechSynthesis != null;

  /// Speak [text] in the given [languageCode] (`vi` or `en`).
  ///
  /// Uses the browser's built-in `speechSynthesis`.  The utterance rate is
  /// slowed slightly (`0.9`) to make it easier for 5‑7 year olds to follow.
  ///
  /// Falls back gracefully if the browser does not support speech synthesis
  /// or does not have a matching voice — `utterance.lang` is always set so
  /// the browser can at least try to select the closest voice.
  void speak(String text, {String languageCode = 'vi'}) {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;

    synth.cancel();
    _trySpeak(synth, text, languageCode: languageCode, attempt: 0);
  }

  void _trySpeak(
    html.SpeechSynthesis synth,
    String text, {
    required String languageCode,
    required int attempt,
  }) {
    final voices = synth.getVoices();
    if (voices.isEmpty && attempt < _maxVoiceRetries) {
      // Browser voices haven't loaded yet. Retry shortly.
      Timer(const Duration(milliseconds: _voiceRetryDelayMs), () {
        _trySpeak(synth, text,
            languageCode: languageCode, attempt: attempt + 1);
      });
      return;
    }

    final utterance = html.SpeechSynthesisUtterance(text);
    utterance.lang = languageCode == 'en' ? 'en-GB' : 'vi-VN';
    utterance.rate = 0.9; // Slightly slower for kids
    utterance.pitch = 1.0;
    utterance.volume = 1.0;

    final targetLang = languageCode == 'en' ? 'en' : 'vi';
    if (voices.isNotEmpty) {
      final voice = voices.cast<html.SpeechSynthesisVoice?>().firstWhere(
        (v) {
          if (v == null) return false;
          return v.lang?.toLowerCase().startsWith(targetLang) ?? false;
        },
        orElse: () => null,
      );
      if (voice != null) {
        utterance.voice = voice;
      }
    }

    synth.speak(utterance);
  }

  /// Stop any ongoing speech.
  void stop() {
    html.window.speechSynthesis?.cancel();
  }
}
