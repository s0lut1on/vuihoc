import 'dart:html' as html;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

/// Web-specific TTS service using the Web Speech API.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  bool get isSupported {
    return html.window.speechSynthesis != null;
  }

  /// Speak [text] in the given [languageCode] (`vi` or `en`).
  ///
  /// Uses the browser's built-in `speechSynthesis` with a Vietnamese or
  /// English voice when available.  The utterance rate is slowed slightly
  /// (`0.9`) to make it easier for 5‑7 year olds to follow.
  void speak(String text, {String languageCode = 'vi'}) {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;

    // Cancel any ongoing speech so we don't overlap.
    synth.cancel();

    final utterance = html.SpeechSynthesisUtterance(text);
    utterance.lang = languageCode == 'en' ? 'en-GB' : 'vi-VN';
    utterance.rate = 0.9; // Slightly slower for kids
    utterance.pitch = 1.0;
    utterance.volume = 1.0;

    // Pick a matching voice if one exists.
    final voices = synth.getVoices();
    final targetLang = languageCode == 'en' ? 'en' : 'vi';
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

    synth.speak(utterance);
  }

  /// Stop any ongoing speech.
  void stop() {
    html.window.speechSynthesis?.cancel();
  }
}
