import 'dart:html' as html;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  html.AudioContext? _ctx;
  bool _muted = false;

  bool get muted => _muted;
  set muted(bool v) => _muted = v;

  html.AudioContext get _context {
    _ctx ??= html.AudioContext();
    return _ctx!;
  }

  void _playTone(double frequency, double duration, {double volume = 0.15}) {
    if (_muted) return;
    try {
      final ctx = _context;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = frequency;
      gain.gain.value = volume;
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(0);
      osc.stop(duration);
    } catch (_) {}
  }

  void _playChord(List<double> frequencies, double duration, {double volume = 0.15}) {
    if (_muted) return;
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
    if (_muted) return;
    Future.delayed(const Duration(milliseconds: 0), () => _playChord([523, 659], 0.2));
    Future.delayed(const Duration(milliseconds: 200), () => _playChord([659, 784], 0.2));
    Future.delayed(const Duration(milliseconds: 400), () => _playChord([784, 1047], 0.3));
  }

  void toggleMute() {
    _muted = !_muted;
  }
}
