import 'dart:async';
import 'dart:html' as html;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

/// Web-specific TTS service using the Web Speech API.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  static const _maxWait = Duration(seconds: 2);
  static const _step = Duration(milliseconds: 50);

  bool get isSupported => html.window.speechSynthesis != null;

  /// Speak [text] in the given [languageCode] (`vi` or `en`).
  ///
  /// Waits up to 2 seconds for Chrome voices to load before selecting a
  /// matching voice and speaking. If no matching voice exists, the browser
  /// will fall back using the closest voice based on utterance.lang.
  void speak(String text, {String languageCode = 'vi'}) async {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;

    // Cancel any ongoing speech.
    synth.cancel();

    // Wait for browser voices (Chrome loads them asynchronously on first use).
    var voices = synth.getVoices();
    var elapsed = Duration.zero;
    while (voices.isEmpty && elapsed < _maxWait) {
      await Future.delayed(_step);
      elapsed += _step;
      voices = synth.getVoices();
    }

    final targetLang = languageCode == 'en' ? 'en-GB' : 'vi-VN';

    // Prefer voices with lang matching 'vi-VN'/'en-GB', then any matching prefix.
    html.SpeechSynthesisVoice? chosen;
    if (voices.isNotEmpty) {
      // Exact match
      for (final v in voices) {
        if (v.lang?.toLowerCase() == targetLang.toLowerCase()) {
          chosen = v;
          break;
        }
      }
      // Prefix match (vi-*, en-*)
      if (chosen == null) {
        final prefix = languageCode.toLowerCase();
        for (final v in voices) {
          if (v.lang?.toLowerCase().startsWith(prefix) ?? false) {
            chosen = v;
            break;
          }
        }
      }
      // Contains match
      if (chosen == null) {
        final prefix = languageCode.toLowerCase();
        for (final v in voices) {
          if (v.lang?.toLowerCase().contains(prefix) ?? false) {
            chosen = v;
            break;
          }
        }
      }
    }

    final u = html.SpeechSynthesisUtterance(text);
    // Set voice FIRST so Chrome derives lang from it.
    // Then override lang explicitly so the right voice is used even when the
    // text content would otherwise make the browser pick English.
    if (chosen != null) {
      u.voice = chosen;
    }
    u.lang = targetLang;
    u.rate = 0.9;
    u.pitch = 1.0;
    u.volume = 1.0;

    synth.speak(u);
  }

  void stop() {
    html.window.speechSynthesis?.cancel();
  }
}
