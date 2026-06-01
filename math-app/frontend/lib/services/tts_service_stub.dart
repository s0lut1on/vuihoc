/// Stub TTS service for non-web platforms (VM tests, mobile, desktop).
///
/// All methods are no-ops so tests compile and run safely.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  bool get isSupported => false;

  void speak(String text, {String languageCode = 'vi'}) {}

  void stop() {}
}
