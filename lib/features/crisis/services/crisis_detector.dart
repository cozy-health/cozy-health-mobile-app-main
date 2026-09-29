enum CrisisSignal { none, soft, hard }

class CrisisDetector {
  static final Map<String, DateTime> _lastTriggered = {};
  static const Duration cooldown = Duration(hours: 4);

  static const List<String> _tier1 = [
    'kill myself',
    'killing myself',
    'end my life',
    'ending my life',
    'end it all',
    'take my own life',
    'suicide',
    'suicidal',
    'want to die',
    'wanna die',
    'better off dead',
    'better off without me',
    'no reason to live',
    'not want to be here',
    "don't want to be here",
    "won't be here tomorrow",
    'hurt myself',
    'hurting myself',
    'self harm',
    'self-harm',
    'cut myself',
    'overdose',
  ];

  static const List<String> _tier2 = [
    'hopeless',
    'worthless',
    'no one cares',
    'nobody cares',
    'no way out',
    'trapped',
    'burden',
    "can't go on",
    "can't take it",
    "can't do this anymore",
    "what's the point",
    'give up',
    'empty',
    'numb',
  ];

  static const List<String> _negativeContexts = [
    'not suicidal',
    'never suicidal',
    'was suicidal',
    'used to be',
    'reading about',
    'researching',
    'studying',
    'helping a friend',
    'someone i know',
  ];

  const CrisisDetector();

  CrisisSignal analyze(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length < 10) return CrisisSignal.none;
    if (_negativeContexts.any(normalized.contains)) return CrisisSignal.none;
    if (_tier1.any(normalized.contains)) return CrisisSignal.hard;

    final matches = _tier2.where(normalized.contains).length;
    return matches >= 2 ? CrisisSignal.soft : CrisisSignal.none;
  }

  bool canTrigger(String surface, CrisisSignal signal, {DateTime? now}) {
    if (signal == CrisisSignal.none) return false;
    final current = now ?? DateTime.now();
    final last = _lastTriggered[surface];
    if (last != null && current.difference(last) < cooldown) return false;
    return true;
  }

  void markTriggered(String surface, {DateTime? now}) {
    _lastTriggered[surface] = now ?? DateTime.now();
  }

  void resetCooldown(String surface) {
    _lastTriggered.remove(surface);
  }
}
