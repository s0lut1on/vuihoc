import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _muted = false;

  bool get muted => _muted;
  set muted(bool v) => _muted = v;

  void _playTone(double frequency, double duration, {double volume = 0.15}) {
    if (_muted || !kIsWeb) return;
    try {
      _webPlayTone(frequency, duration, volume: volume);
    } catch (_) {}
  }

  void _playChord(List<double> frequencies, double duration, {double volume = 0.15}) {
    if (_muted || !kIsWeb) return;
    for (final f in frequencies) {
      _playTone(f, duration, volume: volume / frequencies.length);
    }
  }

  void buttonClick() {
    _playTone(800, 0.05, volume: 0.08);
  }

  void correctAnswer() {
    _playChord([523, 659, 784], 0.3, volume: 0.12);
  }

  void wrongAnswer() {
    _playTone(200, 0.3, volume: 0.1);
  }

  void starEarned() {
    _playChord([1047, 1319, 1568], 0.5, volume: 0.1);
  }

  void celebration() {
    if (_muted || !kIsWeb) return;
    Future.delayed(const Duration(milliseconds: 0), () => _playChord([523, 659], 0.2));
    Future.delayed(const Duration(milliseconds: 200), () => _playChord([659, 784], 0.2));
    Future.delayed(const Duration(milliseconds: 400), () => _playChord([784, 1047], 0.3));
  }

  void toggleMute() {
    _muted = !_muted;
  }
}

void _webPlayTone(double frequency, double duration, {double volume = 0.15}) {
  // No-op: web audio requires dart:html which is unavailable in VM builds
}
