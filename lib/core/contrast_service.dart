/// Whether the OS "Increase Contrast" (iOS) or `prefers-contrast: more` (web)
/// setting is on. Mirrors [MotionService]: the app never exposes its own
/// switch, it follows the system one. Android has no color-contrast
/// preference, so it is never on there.
class ContrastService {
  static final ContrastService _instance = ContrastService._internal();

  factory ContrastService() => _instance;

  ContrastService._internal();

  bool _increaseContrast = false;

  bool get increaseContrast => _increaseContrast;

  void init(bool systemIncreaseContrast) {
    _increaseContrast = systemIncreaseContrast;
  }
}
