class DictionaryEntry {
  const DictionaryEntry({
    required this.english,
    required this.filipino,
    required this.spanish,
  });

  final String english;
  final String filipino;
  final String spanish;

  String valueFor(String language) {
    switch (language.toLowerCase()) {
      case 'filipino':
        return filipino;
      case 'spanish':
        return spanish;
      case 'english':
      default:
        return english;
    }
  }
}

class _TrieNode {
  final Map<String, _TrieNode> children = {};
  final Set<String> words = {};
}

class LanguageTrie {
  LanguageTrie(Iterable<String> words) {
    for (final word in words) {
      insert(word);
    }
  }

  final _TrieNode _root = _TrieNode();

  void insert(String word) {
    var node = _root;
    final normalizedWord = word.trim().toLowerCase();
    if (normalizedWord.isEmpty) {
      return;
    }

    for (final codeUnit in normalizedWord.codeUnits) {
      final letter = String.fromCharCode(codeUnit);
      node = node.children.putIfAbsent(letter, () => _TrieNode());
    }

    node.words.add(word);
  }

  List<String> searchPrefix(String prefix, {int limit = 5}) {
    var node = _root;
    final normalizedPrefix = prefix.trim().toLowerCase();
    if (normalizedPrefix.isEmpty) {
      return [];
    }

    for (final codeUnit in normalizedPrefix.codeUnits) {
      final letter = String.fromCharCode(codeUnit);
      final next = node.children[letter];
      if (next == null) {
        return [];
      }
      node = next;
    }

    final results = <String>[];
    void collect(_TrieNode current) {
      if (results.length >= limit) {
        return;
      }

      results.addAll(current.words.take(limit - results.length));
      final keys = current.children.keys.toList()..sort();
      for (final key in keys) {
        if (results.length >= limit) {
          break;
        }
        collect(current.children[key]!);
      }
    }

    collect(node);
    return results;
  }
}

class LanguageAlgorithms {
  static const List<DictionaryEntry> dictionary = [
    DictionaryEntry(english: 'money', filipino: 'pera', spanish: 'dinero'),
    DictionaryEntry(english: 'circle', filipino: 'bilog', spanish: 'circulo'),
    DictionaryEntry(english: 'paper', filipino: 'papel', spanish: 'papel'),
    DictionaryEntry(english: 'fish', filipino: 'isda', spanish: 'pez'),
    DictionaryEntry(english: 'cat', filipino: 'pusa', spanish: 'gato'),
    DictionaryEntry(english: 'dog', filipino: 'aso', spanish: 'perro'),
    DictionaryEntry(english: 'house', filipino: 'bahay', spanish: 'casa'),
    DictionaryEntry(english: 'sun', filipino: 'araw', spanish: 'sol'),
    DictionaryEntry(english: 'water', filipino: 'tubig', spanish: 'agua'),
    DictionaryEntry(english: 'food', filipino: 'pagkain', spanish: 'comida'),
    DictionaryEntry(english: 'love', filipino: 'pagibig', spanish: 'amor'),
    DictionaryEntry(english: 'book', filipino: 'libro', spanish: 'libro'),
    DictionaryEntry(english: 'chair', filipino: 'upuan', spanish: 'silla'),
    DictionaryEntry(english: 'tree', filipino: 'puno', spanish: 'arbol'),
    DictionaryEntry(english: 'mouse', filipino: 'daga', spanish: 'raton'),
    DictionaryEntry(english: 'pencil', filipino: 'lapis', spanish: 'lapiz'),
    DictionaryEntry(english: 'hello', filipino: 'kumusta', spanish: 'hola'),
    DictionaryEntry(english: 'goodbye', filipino: 'paalam', spanish: 'adios'),
    DictionaryEntry(
      english: 'thank you',
      filipino: 'salamat',
      spanish: 'gracias',
    ),
    DictionaryEntry(
      english: 'please',
      filipino: 'pakiusap',
      spanish: 'por favor',
    ),
    DictionaryEntry(english: 'friend', filipino: 'kaibigan', spanish: 'amigo'),
    DictionaryEntry(
      english: 'school',
      filipino: 'paaralan',
      spanish: 'escuela',
    ),
    DictionaryEntry(english: 'teacher', filipino: 'guro', spanish: 'maestro'),
    DictionaryEntry(
      english: 'student',
      filipino: 'magaaral',
      spanish: 'estudiante',
    ),
    DictionaryEntry(english: 'family', filipino: 'pamilya', spanish: 'familia'),
    DictionaryEntry(english: 'morning', filipino: 'umaga', spanish: 'manana'),
    DictionaryEntry(english: 'night', filipino: 'gabi', spanish: 'noche'),
  ];

  static List<String> wordsForLanguage(String language) {
    return dictionary.map((entry) => entry.valueFor(language)).toList();
  }

  static String? findDirectTranslation({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final normalizedText = _normalize(text);
    for (final entry in dictionary) {
      if (_normalize(entry.valueFor(sourceLanguage)) == normalizedText) {
        return entry.valueFor(targetLanguage);
      }
    }
    return null;
  }

  static List<String> autocomplete({
    required String prefix,
    required String language,
    int limit = 5,
  }) {
    final trie = LanguageTrie(wordsForLanguage(language));
    return trie.searchPrefix(prefix, limit: limit);
  }

  static String? suggestCorrection({
    required String word,
    required String language,
    int maxDistance = 2,
  }) {
    final normalizedWord = _normalize(word);
    if (normalizedWord.length < 3) {
      return null;
    }

    String? bestWord;
    var bestDistance = maxDistance + 1;

    for (final candidate in wordsForLanguage(language)) {
      final distance = levenshteinDistance(
        normalizedWord,
        _normalize(candidate),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestWord = candidate;
      }
    }

    if (bestWord == null || _normalize(bestWord) == normalizedWord) {
      return null;
    }

    return bestDistance <= maxDistance ? bestWord : null;
  }

  static int levenshteinDistance(String first, String second) {
    final rows = first.length + 1;
    final columns = second.length + 1;
    final table = List.generate(rows, (_) => List.filled(columns, 0));

    for (var row = 0; row < rows; row++) {
      table[row][0] = row;
    }
    for (var column = 0; column < columns; column++) {
      table[0][column] = column;
    }

    for (var row = 1; row < rows; row++) {
      for (var column = 1; column < columns; column++) {
        final cost = first[row - 1] == second[column - 1] ? 0 : 1;
        final deletion = table[row - 1][column] + 1;
        final insertion = table[row][column - 1] + 1;
        final substitution = table[row - 1][column - 1] + cost;
        table[row][column] = [deletion, insertion, substitution].reduce(_min);
      }
    }

    return table[first.length][second.length];
  }

  static List<String> rankAlternativeTranslations({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final directTranslation = findDirectTranslation(
      text: originalText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final candidates =
        <String>{
          if (directTranslation != null) directTranslation,
          translatedText,
          translatedText.toLowerCase(),
          _sentenceCase(translatedText),
        }.where((candidate) => candidate.trim().isNotEmpty).toList();

    candidates.sort((left, right) {
      final leftScore = _translationScore(
        candidate: left,
        originalText: originalText,
        directTranslation: directTranslation,
      );
      final rightScore = _translationScore(
        candidate: right,
        originalText: originalText,
        directTranslation: directTranslation,
      );
      return rightScore.compareTo(leftScore);
    });

    return candidates.take(3).toList();
  }

  static int _translationScore({
    required String candidate,
    required String originalText,
    String? directTranslation,
  }) {
    var score = 0;
    final normalizedCandidate = _normalize(candidate);

    if (directTranslation != null &&
        normalizedCandidate == _normalize(directTranslation)) {
      score += 60;
    }

    final lengthDifference = (candidate.length - originalText.length)
        .abs()
        .clamp(0, 20);
    score += 20 - lengthDifference;

    if (candidate.isNotEmpty && candidate[0] == candidate[0].toUpperCase()) {
      score += 8;
    }

    if (!candidate.contains('Alternative')) {
      score += 10;
    }

    return score;
  }

  static int _min(int left, int right) => left < right ? left : right;

  static String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _sentenceCase(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}
