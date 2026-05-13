class DictionaryEntry {
  const DictionaryEntry({
    required this.english,
    required this.filipino,
    required this.spanish,
    required this.japanese,
    required this.russian,
  });

  final String english;
  final String filipino;
  final String spanish;
  final String japanese;
  final String russian;

  String valueFor(String language) {
    switch (language.toLowerCase()) {
      case 'filipino':
        return filipino;
      case 'spanish':
        return spanish;
      case 'japanese':
        return japanese;
      case 'russian':
        return russian;
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
  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'Filipino',
    'Japanese',
    'Russian',
  ];

  static const List<DictionaryEntry> dictionary = [
    DictionaryEntry(
      english: 'money',
      filipino: 'pera',
      spanish: 'dinero',
      japanese: 'お金',
      russian: 'деньги',
    ),
    DictionaryEntry(
      english: 'circle',
      filipino: 'bilog',
      spanish: 'circulo',
      japanese: '円',
      russian: 'круг',
    ),
    DictionaryEntry(
      english: 'paper',
      filipino: 'papel',
      spanish: 'papel',
      japanese: '紙',
      russian: 'бумага',
    ),
    DictionaryEntry(
      english: 'fish',
      filipino: 'isda',
      spanish: 'pez',
      japanese: '魚',
      russian: 'рыба',
    ),
    DictionaryEntry(
      english: 'cat',
      filipino: 'pusa',
      spanish: 'gato',
      japanese: '猫',
      russian: 'кот',
    ),
    DictionaryEntry(
      english: 'dog',
      filipino: 'aso',
      spanish: 'perro',
      japanese: '犬',
      russian: 'собака',
    ),
    DictionaryEntry(
      english: 'house',
      filipino: 'bahay',
      spanish: 'casa',
      japanese: '家',
      russian: 'дом',
    ),
    DictionaryEntry(
      english: 'sun',
      filipino: 'araw',
      spanish: 'sol',
      japanese: '太陽',
      russian: 'солнце',
    ),
    DictionaryEntry(
      english: 'water',
      filipino: 'tubig',
      spanish: 'agua',
      japanese: '水',
      russian: 'вода',
    ),
    DictionaryEntry(
      english: 'food',
      filipino: 'pagkain',
      spanish: 'comida',
      japanese: '食べ物',
      russian: 'еда',
    ),
    DictionaryEntry(
      english: 'love',
      filipino: 'pagibig',
      spanish: 'amor',
      japanese: '愛',
      russian: 'любовь',
    ),
    DictionaryEntry(
      english: 'book',
      filipino: 'libro',
      spanish: 'libro',
      japanese: '本',
      russian: 'книга',
    ),
    DictionaryEntry(
      english: 'chair',
      filipino: 'upuan',
      spanish: 'silla',
      japanese: '椅子',
      russian: 'стул',
    ),
    DictionaryEntry(
      english: 'tree',
      filipino: 'puno',
      spanish: 'arbol',
      japanese: '木',
      russian: 'дерево',
    ),
    DictionaryEntry(
      english: 'mouse',
      filipino: 'daga',
      spanish: 'raton',
      japanese: 'ネズミ',
      russian: 'мышь',
    ),
    DictionaryEntry(
      english: 'pencil',
      filipino: 'lapis',
      spanish: 'lapiz',
      japanese: '鉛筆',
      russian: 'карандаш',
    ),
    DictionaryEntry(
      english: 'hello',
      filipino: 'kumusta',
      spanish: 'hola',
      japanese: 'こんにちは',
      russian: 'привет',
    ),
    DictionaryEntry(
      english: 'goodbye',
      filipino: 'paalam',
      spanish: 'adios',
      japanese: 'さようなら',
      russian: 'до свидания',
    ),
    DictionaryEntry(
      english: 'thank you',
      filipino: 'salamat',
      spanish: 'gracias',
      japanese: 'ありがとう',
      russian: 'спасибо',
    ),
    DictionaryEntry(
      english: 'please',
      filipino: 'pakiusap',
      spanish: 'por favor',
      japanese: 'お願いします',
      russian: 'пожалуйста',
    ),
    DictionaryEntry(
      english: 'friend',
      filipino: 'kaibigan',
      spanish: 'amigo',
      japanese: '友達',
      russian: 'друг',
    ),
    DictionaryEntry(
      english: 'school',
      filipino: 'paaralan',
      spanish: 'escuela',
      japanese: '学校',
      russian: 'школа',
    ),
    DictionaryEntry(
      english: 'teacher',
      filipino: 'guro',
      spanish: 'maestro',
      japanese: '先生',
      russian: 'учитель',
    ),
    DictionaryEntry(
      english: 'student',
      filipino: 'magaaral',
      spanish: 'estudiante',
      japanese: '学生',
      russian: 'студент',
    ),
    DictionaryEntry(
      english: 'family',
      filipino: 'pamilya',
      spanish: 'familia',
      japanese: '家族',
      russian: 'семья',
    ),
    DictionaryEntry(
      english: 'morning',
      filipino: 'umaga',
      spanish: 'manana',
      japanese: '朝',
      russian: 'утро',
    ),
    DictionaryEntry(
      english: 'night',
      filipino: 'gabi',
      spanish: 'noche',
      japanese: '夜',
      russian: 'ночь',
    ),
  ];

  static final Map<String, List<String>> _wordsByLanguage = {
    for (final language in supportedLanguages)
      _languageKey(language): List.unmodifiable(
        dictionary.map((entry) => entry.valueFor(language)),
      ),
  };

  static final Map<String, LanguageTrie> _triesByLanguage = {
    for (final language in supportedLanguages)
      _languageKey(language): LanguageTrie(
        _wordsByLanguage[_languageKey(language)]!,
      ),
  };

  static final Map<String, Map<String, DictionaryEntry>> _entriesByLanguage = {
    for (final language in supportedLanguages)
      _languageKey(language): {
        for (final entry in dictionary)
          _normalize(entry.valueFor(language)): entry,
      },
  };

  static const Map<String, Map<String, List<String>>> _phraseAlternatives = {
    'hello': {
      'spanish': ['¿Qué tal?', '¿Qué onda?', 'Buenos días'],
      'filipino': ['Kamusta ka?', 'Magandang araw', 'Uy'],
      'japanese': ['やあ', 'もしもし', 'おはようございます'],
      'russian': ['здравствуйте', 'добрый день', 'приветствую'],
    },
    'hi': {
      'spanish': ['hola', '¿Qué tal?', 'buenas'],
      'filipino': ['kumusta', 'uy', 'kamusta ka?'],
      'japanese': ['こんにちは', 'やあ', 'どうも'],
      'russian': ['привет', 'здравствуйте', 'добрый день'],
    },
    'good morning': {
      'spanish': ['buenos días', 'buen día', 'qué tengas buen día'],
      'filipino': ['magandang umaga', 'umaga na', 'kamusta ang umaga?'],
      'japanese': ['おはようございます', 'おはよう', '良い朝ですね'],
      'russian': ['доброе утро', 'с добрым утром', 'хорошего утра'],
    },
    'goodbye': {
      'spanish': ['adiós', 'hasta luego', 'nos vemos'],
      'filipino': ['paalam', 'sige, ingat', 'kita tayo ulit'],
      'japanese': ['さようなら', 'またね', 'ではまた'],
      'russian': ['до свидания', 'пока', 'до встречи'],
    },
    'thank you': {
      'spanish': ['gracias', 'muchas gracias', 'te lo agradezco'],
      'filipino': ['salamat', 'maraming salamat', 'salamat po'],
      'japanese': ['ありがとう', 'ありがとうございます', '感謝します'],
      'russian': ['спасибо', 'большое спасибо', 'благодарю'],
    },
    'thanks': {
      'spanish': ['gracias', 'muchas gracias', 'mil gracias'],
      'filipino': ['salamat', 'maraming salamat', 'salamat po'],
      'japanese': ['ありがとう', 'どうもありがとう', 'ありがとうございます'],
      'russian': ['спасибо', 'большое спасибо', 'спасибо большое'],
    },
    'how are you': {
      'spanish': ['¿Cómo estás?', '¿Qué tal?', '¿Cómo te va?'],
      'filipino': ['Kamusta ka?', 'Ayos ka lang?', 'Kumusta naman?'],
      'japanese': ['お元気ですか', '調子はどうですか', '元気？'],
      'russian': ['как дела?', 'как вы?', 'как поживаешь?'],
    },
    'my name is': {
      'spanish': ['me llamo', 'mi nombre es', 'soy'],
      'filipino': [
        'ang pangalan ko ay',
        'ako si',
        'ang pangalan ko po ay',
      ],
      'japanese': ['私の名前は', '私は', 'と申します'],
      'russian': ['меня зовут', 'моё имя', 'я'],
    },
    'can you help me': {
      'spanish': ['¿Puedes ayudarme?', '¿Me ayudas?', 'Necesito ayuda'],
      'filipino': [
        'Pwede mo ba akong tulungan?',
        'Tulungan mo ako',
        'Kailangan ko ng tulong',
      ],
      'japanese': ['手伝ってくれますか', '助けてください', '手伝えますか'],
      'russian': [
        'вы можете мне помочь?',
        'помогите мне, пожалуйста',
        'мне нужна помощь',
      ],
    },
    'i need help': {
      'spanish': ['necesito ayuda', 'ayúdame, por favor', 'me hace falta ayuda'],
      'filipino': [
        'kailangan ko ng tulong',
        'tulungan mo ako',
        'pakitulungan ako',
      ],
      'japanese': ['助けが必要です', '助けてください', '手伝ってください'],
      'russian': ['мне нужна помощь', 'помогите, пожалуйста', 'мне нужна поддержка'],
    },
    'where is the bathroom': {
      'spanish': ['¿Dónde está el baño?', '¿Hay baño?', '¿Dónde queda el baño?'],
      'filipino': [
        'Nasaan ang banyo?',
        'Saan ang CR?',
        'May banyo ba dito?',
      ],
      'japanese': ['トイレはどこですか', 'お手洗いはどこですか', 'トイレはありますか'],
      'russian': ['где туалет?', 'где находится туалет?', 'тут есть туалет?'],
    },
    'where is the station': {
      'spanish': [
        '¿Dónde está la estación?',
        '¿Dónde queda la estación?',
        '¿Cómo llego a la estación?',
      ],
      'filipino': [
        'Nasaan ang istasyon?',
        'Saan ang station?',
        'Paano pumunta sa istasyon?',
      ],
      'japanese': ['駅はどこですか', '駅までどう行きますか', '最寄り駅はどこですか'],
      'russian': ['где станция?', 'как пройти к станции?', 'где ближайшая станция?'],
    },
    'how much is this': {
      'spanish': ['¿Cuánto cuesta?', '¿Cuánto vale?', '¿Cuál es el precio?'],
      'filipino': ['Magkano ito?', 'Ano ang presyo nito?', 'Magkano po?'],
      'japanese': ['これはいくらですか', '値段はいくらですか', 'おいくらですか'],
      'russian': ['сколько это стоит?', 'какая цена?', 'сколько стоит?'],
    },
    'i would like to order': {
      'spanish': ['quisiera pedir', 'me gustaría ordenar', 'quiero pedir'],
      'filipino': [
        'gusto kong umorder',
        'oorder po ako',
        'pwede po akong umorder?',
      ],
      'japanese': ['注文したいです', 'これをお願いします', '注文してもいいですか'],
      'russian': ['я хотел бы заказать', 'можно заказать?', 'я хочу заказать'],
    },
    'good afternoon': {
      'spanish': ['buenas tardes', 'que tengas buena tarde', 'feliz tarde'],
      'filipino': ['magandang hapon', 'maayong hapon', 'kamusta ngayong hapon?'],
      'japanese': ['こんにちは', '良い午後を', '午後もよろしくお願いします'],
      'russian': ['добрый день', 'хорошего дня', 'доброго дня'],
    },
    'good evening': {
      'spanish': ['buenas noches', 'buena noche', 'que tengas buena noche'],
      'filipino': ['magandang gabi', 'maayong gabii', 'kamusta ngayong gabi?'],
      'japanese': ['こんばんは', '良い夜を', '今晩は'],
      'russian': ['добрый вечер', 'хорошего вечера', 'приятного вечера'],
    },
    'i am sorry': {
      'spanish': ['lo siento', 'perdón', 'disculpa'],
      'filipino': ['pasensya na', 'paumanhin', 'sorry po'],
      'japanese': ['ごめんなさい', 'すみません', '申し訳ありません'],
      'russian': ['извините', 'простите', 'мне жаль'],
    },
    'excuse me': {
      'spanish': ['disculpa', 'perdón', 'con permiso'],
      'filipino': ['excuse po', 'makikiraan po', 'paumanhin'],
      'japanese': ['すみません', '失礼します', 'ちょっとすみません'],
      'russian': ['извините', 'простите', 'разрешите'],
    },
    'i do not understand': {
      'spanish': ['no entiendo', 'no comprendo', 'no lo entiendo'],
      'filipino': [
        'hindi ko maintindihan',
        'di ko gets',
        'hindi ko po naiintindihan',
      ],
      'japanese': ['わかりません', '理解できません', 'よくわかりません'],
      'russian': ['я не понимаю', 'не понимаю', 'мне непонятно'],
    },
    'please speak slowly': {
      'spanish': [
        'habla despacio, por favor',
        'puedes hablar más lento?',
        'más despacio, por favor',
      ],
      'filipino': [
        'pakibagalan ang pagsasalita',
        'dahan-dahan lang po',
        'pwede pong mas mabagal?',
      ],
      'japanese': ['ゆっくり話してください', 'もう少しゆっくりお願いします', 'ゆっくりお願いします'],
      'russian': [
        'говорите медленнее, пожалуйста',
        'можно помедленнее?',
        'пожалуйста, медленнее',
      ],
    },
  };

  static const Map<String, List<String>> _phraseCompletions = {
    'english': [
      'hello, my name is',
      'my name is',
      'how are you',
      'where is the bathroom?',
      'where is the nearest station?',
      'can you help me?',
      'thank you very much',
      'good morning',
      'good afternoon',
      'good evening',
      'i would like to order',
      'how much does this cost?',
    ],
    'spanish': [
      'hola, mi nombre es',
      'mi nombre es',
      'como estas?',
      'donde esta el bano?',
      'puedes ayudarme?',
      'muchas gracias',
      'buenos dias',
    ],
    'filipino': [
      'kumusta, ang pangalan ko ay',
      'ang pangalan ko ay',
      'kamusta ka?',
      'nasaan ang banyo?',
      'pwede mo ba akong tulungan?',
      'maraming salamat',
      'magandang umaga',
    ],
    'japanese': [
      'こんにちは、私の名前は',
      '私の名前は',
      'お元気ですか',
      'トイレはどこですか',
      '手伝ってくれますか',
      'ありがとうございます',
      'おはようございます',
    ],
    'russian': [
      'здравствуйте, меня зовут',
      'меня зовут',
      'как дела?',
      'где туалет?',
      'вы можете мне помочь?',
      'большое спасибо',
      'доброе утро',
    ],
  };

  static List<String> wordsForLanguage(String language) {
    return _wordsByLanguage[_languageKey(language)] ?? const [];
  }

  static String? findDirectTranslation({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final normalizedText = _normalize(text);
    final entry =
        _entriesByLanguage[_languageKey(sourceLanguage)]?[normalizedText];
    return entry?.valueFor(targetLanguage);
  }

  static List<String> autocomplete({
    required String prefix,
    required String language,
    int limit = 5,
  }) {
    final trie = _triesByLanguage[_languageKey(language)];
    return trie?.searchPrefix(prefix, limit: limit) ?? const [];
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

  static String? suggestPhraseCompletion({
    required String text,
    required String language,
  }) {
    final normalizedText = _normalize(text);
    if (normalizedText.length < 4) {
      return null;
    }

    final candidates = _phraseCompletions[_languageKey(language)] ?? const [];
    final matches = candidates.where((candidate) {
      final normalizedCandidate = _normalize(candidate);
      return normalizedCandidate != normalizedText &&
          normalizedCandidate.startsWith(normalizedText);
    }).toList()
      ..sort((left, right) => left.length.compareTo(right.length));

    return matches.isEmpty ? null : matches.first;
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
        table[row][column] = _min3(deletion, insertion, substitution);
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
    final contextualAlternatives = _contextualAlternatives(
      text: originalText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    if (contextualAlternatives.isNotEmpty) {
      return _uniqueCandidates(
        contextualAlternatives,
        exclude: {translatedText, if (directTranslation != null) directTranslation},
      ).take(3).toList();
    }

    final candidates =
        <String>{
          if (directTranslation != null) directTranslation,
          translatedText,
          ..._caseVariants(translatedText),
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

  static List<String> _contextualAlternatives({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final sourceKey = _languageKey(sourceLanguage);
    final targetKey = _languageKey(targetLanguage);
    if (sourceKey != 'english' || targetKey == 'english') {
      return const [];
    }

    final normalizedText = _normalize(text);
    final exactAlternatives = _phraseAlternatives[normalizedText]?[targetKey];
    if (exactAlternatives != null) {
      return exactAlternatives;
    }

    return _similarPhraseAlternatives(
      text: normalizedText,
      targetLanguageKey: targetKey,
    );
  }

  static List<String> _similarPhraseAlternatives({
    required String text,
    required String targetLanguageKey,
  }) {
    if (text.length < 4) {
      return const [];
    }

    var bestScore = 0;
    String? bestPhrase;

    for (final phrase in _phraseAlternatives.keys) {
      final score = _phraseSimilarityScore(text, phrase);
      if (score > bestScore) {
        bestScore = score;
        bestPhrase = phrase;
      }
    }

    if (bestPhrase == null || bestScore < 58) {
      return const [];
    }

    return _phraseAlternatives[bestPhrase]?[targetLanguageKey] ?? const [];
  }

  static int _phraseSimilarityScore(String text, String phrase) {
    if (text == phrase) {
      return 100;
    }

    final textTokens = _tokens(text);
    final phraseTokens = _tokens(phrase);
    if (textTokens.isEmpty || phraseTokens.isEmpty) {
      return 0;
    }

    final sharedTokens = textTokens.intersection(phraseTokens).length;
    final smallerTokenCount = textTokens.length < phraseTokens.length
        ? textTokens.length
        : phraseTokens.length;
    final tokenScore = (sharedTokens / smallerTokenCount * 100).round();

    final maxLength = text.length > phrase.length ? text.length : phrase.length;
    final editScore =
        ((1 - (levenshteinDistance(text, phrase) / maxLength)) * 100).round();

    final containsScore = text.contains(phrase) || phrase.contains(text) ? 90 : 0;
    return [tokenScore, editScore, containsScore].reduce(
      (best, score) => score > best ? score : best,
    );
  }

  static Set<String> _tokens(String text) {
    return _normalize(text)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 1)
        .toSet();
  }

  static List<String> _uniqueCandidates(
    Iterable<String> candidates, {
    Set<String> exclude = const {},
  }) {
    final excluded = exclude.map(_normalize).toSet();
    final seen = <String>{};
    final unique = <String>[];

    for (final candidate in candidates) {
      final normalized = _normalize(candidate);
      if (normalized.isEmpty ||
          excluded.contains(normalized) ||
          !seen.add(normalized)) {
        continue;
      }
      unique.add(candidate);
    }

    return unique;
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

    if (_isLatinText(candidate) &&
        candidate.isNotEmpty &&
        candidate[0] == candidate[0].toUpperCase()) {
      score += 8;
    }

    if (!candidate.contains('Alternative')) {
      score += 10;
    }

    return score;
  }

  static int _min3(int first, int second, int third) {
    final smaller = first < second ? first : second;
    return smaller < third ? smaller : third;
  }

  static String _languageKey(String language) {
    return language.trim().toLowerCase();
  }

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

  static Iterable<String> _caseVariants(String text) {
    if (!_isLatinText(text)) {
      return const [];
    }

    return [text.toLowerCase(), _sentenceCase(text)];
  }

  static bool _isLatinText(String text) {
    return RegExp(r'[A-Za-z]').hasMatch(text) &&
        !RegExp(r'[\u0400-\u04ff\u3040-\u30ff\u3400-\u9fff]').hasMatch(text);
  }
}
