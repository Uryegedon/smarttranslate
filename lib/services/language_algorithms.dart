import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _IntentPattern {
  const _IntentPattern({
    required this.id,
    required this.keywords,
    required this.templatesByLanguage,
  });

  final String id;
  final List<String> keywords;
  final Map<String, List<String>> templatesByLanguage;
}

class _ScoredSuggestion {
  const _ScoredSuggestion(this.text, this.score);

  final String text;
  final int score;
}

class VocabularyEntry {
  const VocabularyEntry({
    required this.word,
    required this.score,
    this.category,
    this.aliases = const [],
    this.contexts = const [],
    this.intentWeights = const {},
  });

  factory VocabularyEntry.fromJson(Map<String, dynamic> json) {
    return VocabularyEntry(
      word: json['word'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      category: json['category'] as String?,
      aliases: _stringList(json['aliases']),
      contexts: _stringList(json['contexts']),
      intentWeights: _intMap(json['intentWeights']),
    );
  }

  final String word;
  final int score;
  final String? category;
  final List<String> aliases;
  final List<String> contexts;
  final Map<String, int> intentWeights;

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return List.unmodifiable(value.whereType<String>());
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const {};
    }

    return Map.unmodifiable({
      for (final entry in value.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).round(),
    });
  }
}

class _PhraseSlotTemplate {
  const _PhraseSlotTemplate({
    required this.intent,
    required this.trigger,
    required this.templatesByLanguage,
    required this.slots,
  });

  factory _PhraseSlotTemplate.fromJson(Map<String, dynamic> json) {
    final translations = json['templatesByLanguage'];
    final slots = json['slots'];
    return _PhraseSlotTemplate(
      intent: json['intent'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      templatesByLanguage:
          translations is Map
              ? Map<String, List<String>>.unmodifiable({
                for (final entry in translations.entries)
                  if (entry.key is String && entry.value is List)
                    entry.key as String: List<String>.unmodifiable(
                      (entry.value as List).whereType<String>(),
                    ),
              })
              : const {},
      slots:
          slots is Map
              ? Map<String, Map<String, List<String>>>.unmodifiable({
                for (final entry in slots.entries)
                  if (entry.key is String && entry.value is Map)
                    entry.key
                        as String: Map<String, List<String>>.unmodifiable({
                      for (final language in (entry.value as Map).entries)
                        if (language.key is String && language.value is List)
                          language.key as String: List<String>.unmodifiable(
                            (language.value as List).whereType<String>(),
                          ),
                    }),
              })
              : const {},
    );
  }

  final String intent;
  final String trigger;
  final Map<String, List<String>> templatesByLanguage;
  final Map<String, Map<String, List<String>>> slots;
}

class _VocabularyIndex {
  _VocabularyIndex(Iterable<VocabularyEntry> entries) {
    final sortedEntries =
        entries.toList()..sort((left, right) {
          final scoreOrder = right.score.compareTo(left.score);
          if (scoreOrder != 0) {
            return scoreOrder;
          }
          return left.word.length.compareTo(right.word.length);
        });

    this.entries = List.unmodifiable(sortedEntries);
    for (final entry in sortedEntries) {
      final normalizedWord = LanguageAlgorithms._normalize(entry.word);
      if (normalizedWord.length < 2 ||
          !LanguageAlgorithms._isAutocompleteCandidateWord(entry.word)) {
        continue;
      }
      for (var length = 2; length <= normalizedWord.length; length++) {
        final prefix = normalizedWord.substring(0, length);
        _byPrefix.putIfAbsent(prefix, () => []).add(entry);
      }
    }
  }

  late final List<VocabularyEntry> entries;
  final Map<String, List<VocabularyEntry>> _byPrefix = {};

  List<VocabularyEntry> searchPrefix(String prefix) {
    return _byPrefix[prefix] ?? const [];
  }

  List<VocabularyEntry> searchableEntries() => entries;
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
    DictionaryEntry(
      english: 'phone',
      filipino: 'telepono',
      spanish: 'telefono',
      japanese: '電話',
      russian: 'телефон',
    ),
    DictionaryEntry(
      english: 'charger',
      filipino: 'charger',
      spanish: 'cargador',
      japanese: '充電器',
      russian: 'зарядка',
    ),
    DictionaryEntry(
      english: 'ticket',
      filipino: 'tiket',
      spanish: 'boleto',
      japanese: '切符',
      russian: 'билет',
    ),
    DictionaryEntry(
      english: 'station',
      filipino: 'istasyon',
      spanish: 'estacion',
      japanese: '駅',
      russian: 'станция',
    ),
    DictionaryEntry(
      english: 'airport',
      filipino: 'paliparan',
      spanish: 'aeropuerto',
      japanese: '空港',
      russian: 'аэропорт',
    ),
    DictionaryEntry(
      english: 'hotel',
      filipino: 'hotel',
      spanish: 'hotel',
      japanese: 'ホテル',
      russian: 'отель',
    ),
    DictionaryEntry(
      english: 'hospital',
      filipino: 'ospital',
      spanish: 'hospital',
      japanese: '病院',
      russian: 'больница',
    ),
    DictionaryEntry(
      english: 'pharmacy',
      filipino: 'botika',
      spanish: 'farmacia',
      japanese: '薬局',
      russian: 'аптека',
    ),
    DictionaryEntry(
      english: 'passport',
      filipino: 'pasaporte',
      spanish: 'pasaporte',
      japanese: 'パスポート',
      russian: 'паспорт',
    ),
    DictionaryEntry(
      english: 'luggage',
      filipino: 'bagahe',
      spanish: 'equipaje',
      japanese: '荷物',
      russian: 'багаж',
    ),
    DictionaryEntry(
      english: 'bathroom',
      filipino: 'banyo',
      spanish: 'bano',
      japanese: 'トイレ',
      russian: 'туалет',
    ),
    DictionaryEntry(
      english: 'coffee',
      filipino: 'kape',
      spanish: 'cafe',
      japanese: 'コーヒー',
      russian: 'кофе',
    ),
    DictionaryEntry(
      english: 'medicine',
      filipino: 'gamot',
      spanish: 'medicina',
      japanese: '薬',
      russian: 'лекарство',
    ),
    DictionaryEntry(
      english: 'receipt',
      filipino: 'resibo',
      spanish: 'recibo',
      japanese: '領収書',
      russian: 'чек',
    ),
    DictionaryEntry(
      english: 'entrance',
      filipino: 'pasukan',
      spanish: 'entrada',
      japanese: '入口',
      russian: 'вход',
    ),
    DictionaryEntry(
      english: 'exit',
      filipino: 'labasan',
      spanish: 'salida',
      japanese: '出口',
      russian: 'выход',
    ),
    DictionaryEntry(
      english: 'schedule',
      filipino: 'iskedyul',
      spanish: 'horario',
      japanese: '時刻表',
      russian: 'расписание',
    ),
    DictionaryEntry(
      english: 'reservation',
      filipino: 'reserbasyon',
      spanish: 'reserva',
      japanese: '予約',
      russian: 'бронь',
    ),
    DictionaryEntry(
      english: 'available',
      filipino: 'available',
      spanish: 'disponible',
      japanese: '利用可能',
      russian: 'доступно',
    ),
    DictionaryEntry(
      english: 'emergency',
      filipino: 'emergency',
      spanish: 'emergencia',
      japanese: '緊急',
      russian: 'срочно',
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

  static Map<String, _VocabularyIndex> _vocabularyByLanguage = const {};
  static Map<String, int> _acceptedSuggestionCounts = const {};
  static List<_PhraseSlotTemplate> _phraseSlotTemplates = const [];
  static bool _vocabularyLoaded = false;
  static const String _usagePrefsKey =
      'language_algorithms.accepted_suggestions.v1';

  static Future<void> loadVocabulary({
    String assetDirectory = 'assets/vocabulary',
    bool force = false,
  }) async {
    if (_vocabularyLoaded && !force) {
      return;
    }

    final loadedVocabulary = <String, _VocabularyIndex>{};
    for (final language in supportedLanguages) {
      final languageKey = _languageKey(language);
      try {
        final jsonText = await rootBundle.loadString(
          '$assetDirectory/$languageKey.json',
        );
        final decoded = jsonDecode(jsonText);
        if (decoded is! List) {
          continue;
        }

        final entries =
            decoded
                .whereType<Map<String, dynamic>>()
                .map(VocabularyEntry.fromJson)
                .where((entry) => _normalize(entry.word).isNotEmpty)
                .toList();

        if (entries.isNotEmpty) {
          loadedVocabulary[languageKey] = _VocabularyIndex(entries);
        }
      } on FlutterError {
        continue;
      } on FormatException {
        continue;
      }
    }

    _phraseSlotTemplates = await _loadPhraseSlotTemplates(assetDirectory);
    _acceptedSuggestionCounts = await _loadAcceptedSuggestionCounts();
    _vocabularyByLanguage = Map.unmodifiable(loadedVocabulary);
    _vocabularyLoaded = true;
  }

  static Future<void> recordAcceptedAutocomplete({
    required String word,
    required String language,
  }) async {
    final normalizedWord = _normalize(word);
    if (normalizedWord.isEmpty) {
      return;
    }

    final key = '${_languageKey(language)}|$normalizedWord';
    final updated = Map<String, int>.from(_acceptedSuggestionCounts);
    updated[key] = (updated[key] ?? 0) + 1;
    _acceptedSuggestionCounts = Map.unmodifiable(updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _usagePrefsKey,
        jsonEncode(_acceptedSuggestionCounts),
      );
    } catch (_) {
      // Usage learning is optional; autocomplete should still work without it.
    }
  }

  static Future<List<_PhraseSlotTemplate>> _loadPhraseSlotTemplates(
    String assetDirectory,
  ) async {
    try {
      final jsonText = await rootBundle.loadString(
        '$assetDirectory/phrase_slots.json',
      );
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) {
        return const [];
      }

      return List.unmodifiable(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(_PhraseSlotTemplate.fromJson)
            .where((template) => template.trigger.trim().isNotEmpty),
      );
    } on FlutterError {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  static Future<Map<String, int>> _loadAcceptedSuggestionCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonText = prefs.getString(_usagePrefsKey);
      if (jsonText == null || jsonText.isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return const {};
      }

      return Map.unmodifiable({
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).round(),
      });
    } catch (_) {
      return const {};
    }
  }

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
      'filipino': ['ang pangalan ko ay', 'ako si', 'ang pangalan ko po ay'],
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
      'spanish': [
        'necesito ayuda',
        'ayúdame, por favor',
        'me hace falta ayuda',
      ],
      'filipino': [
        'kailangan ko ng tulong',
        'tulungan mo ako',
        'pakitulungan ako',
      ],
      'japanese': ['助けが必要です', '助けてください', '手伝ってください'],
      'russian': [
        'мне нужна помощь',
        'помогите, пожалуйста',
        'мне нужна поддержка',
      ],
    },
    'where is the bathroom': {
      'spanish': [
        '¿Dónde está el baño?',
        '¿Hay baño?',
        '¿Dónde queda el baño?',
      ],
      'filipino': ['Nasaan ang banyo?', 'Saan ang CR?', 'May banyo ba dito?'],
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
      'russian': [
        'где станция?',
        'как пройти к станции?',
        'где ближайшая станция?',
      ],
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
      'filipino': [
        'magandang hapon',
        'maayong hapon',
        'kamusta ngayong hapon?',
      ],
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

  static const List<String> _contextStopWords = [
    'a',
    'an',
    'and',
    'any',
    'are',
    'can',
    'could',
    'do',
    'does',
    'for',
    'get',
    'give',
    'have',
    'i',
    'is',
    'me',
    'my',
    'need',
    'please',
    'some',
    'the',
    'this',
    'to',
    'want',
    'where',
    'you',
  ];

  static const List<String> _contextActionWords = [
    'assist',
    'buy',
    'cost',
    'eat',
    'find',
    'get',
    'go',
    'help',
    'hungry',
    'need',
    'order',
    'pay',
    'please',
    'purchase',
    'sell',
    'want',
  ];

  static const Map<String, Map<String, String>> _intentDefaultObjects = {
    'food_ordering': {
      'english': 'food',
      'spanish': 'comida',
      'filipino': 'pagkain',
      'japanese': '食べ物',
      'russian': 'еду',
    },
    'shopping': {
      'english': 'this item',
      'spanish': 'este artículo',
      'filipino': 'item na ito',
      'japanese': 'この商品',
      'russian': 'этот товар',
    },
    'travel': {
      'english': 'the station',
      'spanish': 'la estación',
      'filipino': 'istasyon',
      'japanese': '駅',
      'russian': 'станция',
    },
    'help': {
      'english': 'this',
      'spanish': 'esto',
      'filipino': 'ito',
      'japanese': 'これ',
      'russian': 'этим',
    },
  };

  static const List<_IntentPattern> _intentPatterns = [
    _IntentPattern(
      id: 'food_ordering',
      keywords: [
        'eat',
        'food',
        'hungry',
        'meal',
        'menu',
        'order',
        'restaurant',
        'rice',
        'water',
        'drink',
      ],
      templatesByLanguage: {
        'english': [
          'I would like to order {object}.',
          'Can I see the menu?',
          'How much is {object}?',
        ],
        'spanish': [
          'Quisiera pedir {object}.',
          '¿Puedo ver el menú?',
          '¿Cuánto cuesta {object}?',
        ],
        'filipino': [
          'Gusto kong umorder ng {object}.',
          'Pwede ko bang makita ang menu?',
          'Magkano ang {object}?',
        ],
        'japanese': ['{object}を注文したいです。', 'メニューを見てもいいですか。', '{object}はいくらですか。'],
        'russian': [
          'Я хотел бы заказать {object}.',
          'Можно посмотреть меню?',
          'Сколько стоит {object}?',
        ],
      },
    ),
    _IntentPattern(
      id: 'shopping',
      keywords: [
        'buy',
        'cost',
        'find',
        'pay',
        'price',
        'purchase',
        'sell',
        'store',
        'charger',
        'medicine',
        'ticket',
      ],
      templatesByLanguage: {
        'english': [
          'Where can I buy {object}?',
          'How much does {object} cost?',
          'I need {object}.',
        ],
        'spanish': [
          '¿Dónde puedo comprar {object}?',
          '¿Cuánto cuesta {object}?',
          'Necesito {object}.',
        ],
        'filipino': [
          'Saan ako makakabili ng {object}?',
          'Magkano ang {object}?',
          'Kailangan ko ng {object}.',
        ],
        'japanese': [
          '{object}はどこで買えますか。',
          '{object}はいくらですか。',
          '{object}が必要です。',
        ],
        'russian': [
          'Где можно купить {object}?',
          'Сколько стоит {object}?',
          'Мне нужен {object}.',
        ],
      },
    ),
    _IntentPattern(
      id: 'travel',
      keywords: [
        'airport',
        'bus',
        'direction',
        'directions',
        'fare',
        'go',
        'hotel',
        'ride',
        'station',
        'taxi',
        'train',
      ],
      templatesByLanguage: {
        'english': [
          'How do I get to {object}?',
          'Where is {object}?',
          'How much is the fare?',
        ],
        'spanish': [
          '¿Cómo llego a {object}?',
          '¿Dónde está {object}?',
          '¿Cuánto cuesta el pasaje?',
        ],
        'filipino': [
          'Paano pumunta sa {object}?',
          'Nasaan ang {object}?',
          'Magkano ang pamasahe?',
        ],
        'japanese': ['{object}までどう行きますか。', '{object}はどこですか。', '運賃はいくらですか。'],
        'russian': [
          'Как добраться до {object}?',
          'Где находится {object}?',
          'Сколько стоит проезд?',
        ],
      },
    ),
    _IntentPattern(
      id: 'help',
      keywords: [
        'assist',
        'broken',
        'emergency',
        'help',
        'lost',
        'problem',
        'support',
        'trouble',
      ],
      templatesByLanguage: {
        'english': [
          'Can you help me?',
          'I need help with {object}.',
          'This is an emergency.',
        ],
        'spanish': [
          '¿Puede ayudarme?',
          'Necesito ayuda con {object}.',
          'Esto es una emergencia.',
        ],
        'filipino': [
          'Pwede mo ba akong tulungan?',
          'Kailangan ko ng tulong sa {object}.',
          'Emergency ito.',
        ],
        'japanese': ['手伝ってくれますか。', '{object}について助けが必要です。', '緊急です。'],
        'russian': [
          'Вы можете мне помочь?',
          'Мне нужна помощь с {object}.',
          'Это чрезвычайная ситуация.',
        ],
      },
    ),
  ];

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

  static List<String> autocompleteText({
    required String text,
    required String language,
    int limit = 5,
  }) {
    final normalizedText = _normalize(text);
    if (normalizedText.isEmpty) {
      return const [];
    }

    final activeWord = _activeWordFrom(normalizedText);
    if (activeWord.length < 2) {
      return const [];
    }

    final languageKey = _languageKey(language);
    final phraseWordMatches = _phraseWordAutocompleteMatches(
      text: normalizedText,
      languageKey: languageKey,
    );
    final dictionaryMatches = autocomplete(
          prefix: activeWord,
          language: language,
        )
        .where(_isAutocompleteCandidateWord)
        .map((word) => _ScoredSuggestion(word, 100));
    final vocabularyMatches = _vocabularyAutocompleteMatches(
      text: normalizedText,
      activeWord: activeWord,
      languageKey: languageKey,
    );

    return _rankAutocompleteCandidates(
      activeWord: activeWord,
      candidates: [
        ...phraseWordMatches.map((word) => _ScoredSuggestion(word, 500)),
        ...dictionaryMatches,
        ...vocabularyMatches,
      ],
    ).take(limit).toList();
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
    var bestDistance = maxDistance + 1.0;

    for (final candidate in _correctionCandidates(language)) {
      final distance = _weightedTypoDistance(
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
    if (_isCompleteSingleKnownWord(
      text: normalizedText,
      languageKey: _languageKey(language),
    )) {
      return null;
    }

    final candidates = _phraseCompletions[_languageKey(language)] ?? const [];
    final scoredSuggestions = <_ScoredSuggestion>[];

    final prefixMatches = candidates.where((candidate) {
      final normalizedCandidate = _normalize(candidate);
      return normalizedCandidate != normalizedText &&
          normalizedCandidate.startsWith(normalizedText);
    });

    for (final candidate in prefixMatches) {
      scoredSuggestions.add(
        _ScoredSuggestion(candidate, 220 - candidate.length.clamp(0, 120)),
      );
    }

    for (final candidate in candidates) {
      final normalizedCandidate = _normalize(candidate);
      if (normalizedCandidate == normalizedText ||
          normalizedCandidate.startsWith(normalizedText)) {
        continue;
      }

      final score = _phraseSimilarityScore(normalizedText, normalizedCandidate);
      if (score >= 72 &&
          _isPlausiblePhraseMatch(normalizedText, normalizedCandidate, score)) {
        scoredSuggestions.add(_ScoredSuggestion(candidate, score + 30));
      }
    }

    scoredSuggestions.addAll(
      _phraseSlotSuggestions(
        text: normalizedText,
        sourceLanguageKey: _languageKey(language),
        outputLanguageKey: _languageKey(language),
      ),
    );

    scoredSuggestions.addAll(
      _intentSuggestions(
        text: normalizedText,
        sourceLanguageKey: _languageKey(language),
        outputLanguageKey: _languageKey(language),
      ),
    );

    scoredSuggestions.sort((left, right) {
      final scoreComparison = right.score.compareTo(left.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return left.text.length.compareTo(right.text.length);
    });

    final unique = _uniqueCandidates(
      scoredSuggestions.map((suggestion) => suggestion.text),
      exclude: {normalizedText},
    );

    return unique.isEmpty ? null : unique.first;
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

  static List<String> _correctionCandidates(String language) {
    final languageKey = _languageKey(language);
    final vocabulary = _vocabularyByLanguage[languageKey];
    return _uniqueCandidates([
      ...(_commonCorrectionWordsByLanguage[languageKey] ?? const []),
      ...wordsForLanguage(language),
      if (vocabulary != null)
        for (final entry in vocabulary.searchableEntries()) ...[
          entry.word,
          ...entry.aliases,
        ],
    ]);
  }

  static const Map<String, List<String>> _commonCorrectionWordsByLanguage = {
    'english': [
      'what',
      'where',
      'when',
      'who',
      'why',
      'how',
      'which',
      'this',
      'that',
      'there',
      'please',
      'thanks',
    ],
    'spanish': [
      'que',
      'qué',
      'donde',
      'dónde',
      'cuando',
      'cuándo',
      'quien',
      'quién',
      'por qué',
      'como',
      'cómo',
      'este',
      'esta',
      'por favor',
      'gracias',
    ],
    'filipino': [
      'ano',
      'saan',
      'kailan',
      'sino',
      'bakit',
      'paano',
      'ito',
      'iyan',
      'pakiusap',
      'salamat',
    ],
    'japanese': ['何', 'どこ', 'いつ', '誰', 'なぜ', 'どう', 'これ', 'それ', 'お願いします'],
    'russian': [
      'что',
      'где',
      'когда',
      'кто',
      'почему',
      'как',
      'этот',
      'это',
      'пожалуйста',
      'спасибо',
    ],
  };

  static double _weightedTypoDistance(String first, String second) {
    if (first == second) {
      return 0;
    }
    if (!_isLatinText(first) || !_isLatinText(second)) {
      return levenshteinDistance(first, second).toDouble();
    }

    final rows = first.length + 1;
    final columns = second.length + 1;
    final table = List.generate(rows, (_) => List.filled(columns, 0.0));

    for (var row = 0; row < rows; row++) {
      table[row][0] = row.toDouble();
    }
    for (var column = 0; column < columns; column++) {
      table[0][column] = column.toDouble();
    }

    for (var row = 1; row < rows; row++) {
      for (var column = 1; column < columns; column++) {
        final left = first[row - 1];
        final right = second[column - 1];
        final substitutionCost =
            left == right ? 0.0 : _keyboardSubstitutionCost(left, right);
        final deletion = table[row - 1][column] + 1;
        final insertion = table[row][column - 1] + 1;
        final substitution = table[row - 1][column - 1] + substitutionCost;
        table[row][column] = [
          deletion,
          insertion,
          substitution,
        ].reduce((best, value) => value < best ? value : best);
      }
    }

    return table[first.length][second.length];
  }

  static double _keyboardSubstitutionCost(String left, String right) {
    final leftNeighbors = _keyboardNeighbors[left.toLowerCase()] ?? const {};
    if (leftNeighbors.contains(right.toLowerCase())) {
      return 0.65;
    }
    return 1;
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
        exclude: {
          translatedText,
          if (directTranslation != null) directTranslation,
        },
      ).take(3).toList();
    }

    if (directTranslation == null) {
      return const [];
    }

    final candidates =
        <String>{
          directTranslation,
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

    final similarAlternatives = _similarPhraseAlternatives(
      text: normalizedText,
      targetLanguageKey: targetKey,
    );
    final intentAlternatives = _intentSuggestions(
      text: normalizedText,
      sourceLanguageKey: sourceKey,
      outputLanguageKey: targetKey,
    ).map((suggestion) => suggestion.text);
    final slotAlternatives = _phraseSlotSuggestions(
      text: normalizedText,
      sourceLanguageKey: sourceKey,
      outputLanguageKey: targetKey,
    ).map((suggestion) => suggestion.text);

    return _uniqueCandidates([
      ...similarAlternatives,
      ...slotAlternatives,
      ...intentAlternatives,
    ]).take(3).toList();
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

    if (bestPhrase == null ||
        bestScore < 72 ||
        !_isPlausiblePhraseMatch(text, bestPhrase, bestScore)) {
      return const [];
    }

    return _phraseAlternatives[bestPhrase]?[targetLanguageKey] ?? const [];
  }

  static List<_ScoredSuggestion> _phraseSlotSuggestions({
    required String text,
    required String sourceLanguageKey,
    required String outputLanguageKey,
  }) {
    if (_phraseSlotTemplates.isEmpty || text.length < 4) {
      return const [];
    }

    final suggestions = <_ScoredSuggestion>[];
    for (final template in _phraseSlotTemplates) {
      final sourceTemplates = template.templatesByLanguage[sourceLanguageKey];
      final outputTemplates = template.templatesByLanguage[outputLanguageKey];
      if (sourceTemplates == null ||
          sourceTemplates.isEmpty ||
          outputTemplates == null ||
          outputTemplates.isEmpty) {
        continue;
      }

      if (template.slots.isEmpty) {
        continue;
      }
      final slotValuesByLanguage = template.slots.values.first;
      final sourceSlotValues = slotValuesByLanguage[sourceLanguageKey];
      final outputSlotValues = slotValuesByLanguage[outputLanguageKey];
      if (sourceSlotValues == null ||
          outputSlotValues == null ||
          sourceSlotValues.isEmpty ||
          outputSlotValues.isEmpty) {
        continue;
      }

      final sourceTemplate = sourceTemplates.first;
      final outputTemplate = outputTemplates.first;
      final slotName = _firstSlotName(sourceTemplate);
      if (slotName == null) {
        continue;
      }

      final sourcePrefix = _normalize(
        sourceTemplate.substring(0, sourceTemplate.indexOf('{$slotName}')),
      );
      if (!text.startsWith(sourcePrefix.trim()) &&
          _phraseSimilarityScore(text, sourcePrefix) < 62) {
        continue;
      }

      for (var index = 0; index < sourceSlotValues.length; index++) {
        final sourceValue = sourceSlotValues[index];
        final outputValue =
            index < outputSlotValues.length
                ? outputSlotValues[index]
                : sourceValue;
        final sourcePhrase = _normalize(
          sourceTemplate.replaceAll('{$slotName}', sourceValue),
        );
        if (!sourcePhrase.startsWith(text) &&
            _phraseSimilarityScore(text, sourcePhrase) < 62) {
          continue;
        }

        final outputPhrase = outputTemplate.replaceAll(
          '{$slotName}',
          outputValue,
        );
        suggestions.add(
          _ScoredSuggestion(
            outputPhrase,
            140 + _phraseSimilarityScore(text, sourcePhrase),
          ),
        );
      }
    }

    suggestions.sort((left, right) => right.score.compareTo(left.score));
    return suggestions;
  }

  static String? _firstSlotName(String template) {
    final match = RegExp(r'\{([a-zA-Z0-9_]+)\}').firstMatch(template);
    return match?.group(1);
  }

  static List<_ScoredSuggestion> _intentSuggestions({
    required String text,
    required String sourceLanguageKey,
    required String outputLanguageKey,
  }) {
    if (text.length < 4) {
      return const [];
    }

    final tokenList = _orderedTokens(text);
    if (tokenList.isEmpty) {
      return const [];
    }

    final suggestions = <_ScoredSuggestion>[];
    for (final pattern in _intentPatterns) {
      final keywordScore = _intentKeywordScore(
        text: text,
        tokenList: tokenList,
        pattern: pattern,
      );
      if (keywordScore == 0) {
        continue;
      }

      final templates = pattern.templatesByLanguage[outputLanguageKey];
      if (templates == null || templates.isEmpty) {
        continue;
      }

      final object = _contextObject(
        text: text,
        tokens: tokenList,
        pattern: pattern,
        sourceLanguageKey: sourceLanguageKey,
        outputLanguageKey: outputLanguageKey,
      );

      for (var index = 0; index < templates.length; index++) {
        final template = templates[index];
        suggestions.add(
          _ScoredSuggestion(
            template.replaceAll('{object}', object),
            95 + keywordScore - (index * 6),
          ),
        );
      }
    }

    suggestions.sort((left, right) => right.score.compareTo(left.score));
    return suggestions;
  }

  static int _intentKeywordScore({
    required String text,
    required List<String> tokenList,
    required _IntentPattern pattern,
  }) {
    final tokens = tokenList.toSet();
    var score = 0;
    var directScore = 0;
    for (final keyword in pattern.keywords) {
      if (keyword.contains(' ')) {
        if (text.contains(keyword)) {
          score += 18;
          directScore += 18;
        }
        continue;
      }

      if (tokens.contains(keyword)) {
        score += 18;
        directScore += 18;
      }
    }

    if (directScore == 0) {
      return 0;
    }

    for (final chunk in _ngrams(tokenList, maxSize: 3)) {
      for (final keyword in pattern.keywords) {
        if (keyword.length < 4) {
          continue;
        }
        final scoreCandidate = _phraseSimilarityScore(chunk, keyword);
        if (scoreCandidate >= 78) {
          score += 8;
        }
      }
    }

    return score.clamp(0, 70);
  }

  static String _contextObject({
    required String text,
    required List<String> tokens,
    required _IntentPattern pattern,
    required String sourceLanguageKey,
    required String outputLanguageKey,
  }) {
    final objectTokens =
        tokens.where((token) {
          return !_contextStopWords.contains(token) &&
              !_contextActionWords.contains(token);
        }).toList();

    final sourceObject =
        objectTokens.isEmpty
            ? _defaultObject(pattern.id, sourceLanguageKey)
            : objectTokens.take(3).join(' ');

    if (outputLanguageKey == sourceLanguageKey) {
      return sourceObject;
    }

    final translatedObject = findDirectTranslation(
      text: sourceObject,
      sourceLanguage: sourceLanguageKey,
      targetLanguage: outputLanguageKey,
    );
    if (translatedObject != null && translatedObject.trim().isNotEmpty) {
      return translatedObject;
    }

    final slotObject = _translateSlotValue(
      sourceObject: sourceObject,
      sourceLanguageKey: sourceLanguageKey,
      outputLanguageKey: outputLanguageKey,
    );
    if (slotObject != null) {
      return slotObject;
    }

    return _defaultObject(pattern.id, outputLanguageKey);
  }

  static String? _translateSlotValue({
    required String sourceObject,
    required String sourceLanguageKey,
    required String outputLanguageKey,
  }) {
    final normalizedObject = _normalize(sourceObject);
    for (final template in _phraseSlotTemplates) {
      for (final slotValuesByLanguage in template.slots.values) {
        final sourceValues = slotValuesByLanguage[sourceLanguageKey];
        final outputValues = slotValuesByLanguage[outputLanguageKey];
        if (sourceValues == null || outputValues == null) {
          continue;
        }
        for (var index = 0; index < sourceValues.length; index++) {
          if (_normalize(sourceValues[index]) != normalizedObject) {
            continue;
          }
          if (index < outputValues.length) {
            return outputValues[index];
          }
        }
      }
    }

    return null;
  }

  static String _defaultObject(String intentId, String languageKey) {
    return _intentDefaultObjects[intentId]?[languageKey] ??
        _intentDefaultObjects[intentId]?['english'] ??
        'this';
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
    final smallerTokenCount =
        textTokens.length < phraseTokens.length
            ? textTokens.length
            : phraseTokens.length;
    final tokenScore = (sharedTokens / smallerTokenCount * 100).round();

    final maxLength = text.length > phrase.length ? text.length : phrase.length;
    final editScore =
        ((1 - (levenshteinDistance(text, phrase) / maxLength)) * 100).round();

    final containsScore =
        text.contains(phrase) || phrase.contains(text) ? 90 : 0;
    return [
      tokenScore,
      editScore,
      containsScore,
    ].reduce((best, score) => score > best ? score : best);
  }

  static bool _isPlausiblePhraseMatch(String text, String phrase, int score) {
    if (text == phrase ||
        text.startsWith(phrase) ||
        phrase.startsWith(text) ||
        text.contains(phrase) ||
        phrase.contains(text)) {
      return true;
    }

    if (_meaningfulTokens(
      text,
    ).intersection(_meaningfulTokens(phrase)).isNotEmpty) {
      return true;
    }

    return score >= 84;
  }

  static Set<String> _meaningfulTokens(String text) {
    return _orderedTokens(
      text,
    ).where((token) => !_fuzzyPhraseStopWords.contains(token)).toSet();
  }

  static const Set<String> _fuzzyPhraseStopWords = {
    'a',
    'an',
    'and',
    'are',
    'can',
    'could',
    'did',
    'does',
    'he',
    'i',
    'is',
    'it',
    'me',
    'my',
    'of',
    'say',
    'she',
    'the',
    'this',
    'to',
    'what',
    'where',
    'who',
    'why',
    'you',
  };

  static Set<String> _tokens(String text) {
    return _orderedTokens(text).toSet();
  }

  static List<String> _phraseWordAutocompleteMatches({
    required String text,
    required String languageKey,
  }) {
    final candidates = _phraseCompletions[languageKey] ?? const [];
    final inputWords = _wordsBySpace(text);
    if (inputWords.isEmpty) {
      return const [];
    }

    final activeIndex = inputWords.length - 1;
    final activeWord = inputWords[activeIndex];
    final matches = <String>[];
    for (final candidate in candidates) {
      final normalizedCandidateWords = _wordsBySpace(_normalize(candidate));
      final displayCandidateWords = _wordsBySpace(candidate);
      if (activeIndex >= normalizedCandidateWords.length ||
          activeIndex >= displayCandidateWords.length) {
        continue;
      }

      var previousWordsMatch = true;
      for (var index = 0; index < activeIndex; index++) {
        if (inputWords[index] != normalizedCandidateWords[index]) {
          previousWordsMatch = false;
          break;
        }
      }
      if (!previousWordsMatch) {
        continue;
      }

      final candidateWord = normalizedCandidateWords[activeIndex];
      if (candidateWord != activeWord && candidateWord.startsWith(activeWord)) {
        matches.add(displayCandidateWords[activeIndex]);
      }
    }

    matches.sort((left, right) => left.length.compareTo(right.length));

    return matches;
  }

  static List<_ScoredSuggestion> _vocabularyAutocompleteMatches({
    required String text,
    required String activeWord,
    required String languageKey,
  }) {
    final vocabulary = _vocabularyByLanguage[languageKey];
    if (vocabulary == null) {
      return const [];
    }

    final inputTokens = _wordsBySpace(text);
    final contextTokens =
        inputTokens.length <= 1
            ? const <String>[]
            : inputTokens.sublist(0, inputTokens.length - 1);
    final intentScores = _rankedContextIntents(
      contextTokens: contextTokens,
      languageKey: languageKey,
    );
    final matches = <_ScoredSuggestion>[];

    for (final entry in vocabulary.searchPrefix(activeWord)) {
      final normalizedWord = _normalize(entry.word);
      if (normalizedWord == activeWord ||
          !normalizedWord.startsWith(activeWord) ||
          !_isAutocompleteCandidateWord(entry.word)) {
        continue;
      }

      final intentBoost = _intentBoostForEntry(entry, intentScores);
      final contextBoost = _entryContextBoost(entry, contextTokens);
      final usageBoost = _usageBoost(languageKey, normalizedWord);
      matches.add(
        _ScoredSuggestion(
          entry.word,
          200 + entry.score + intentBoost + contextBoost + usageBoost,
        ),
      );
    }

    return matches;
  }

  static List<String> _rankAutocompleteCandidates({
    required String activeWord,
    required Iterable<_ScoredSuggestion> candidates,
  }) {
    final bestByWord = <String, _ScoredSuggestion>{};
    for (final candidate in candidates) {
      final normalizedSuggestion = _normalize(candidate.text);
      if (normalizedSuggestion == activeWord ||
          !normalizedSuggestion.startsWith(activeWord) ||
          !_isSingleAutocompleteWord(candidate.text)) {
        continue;
      }

      final current = bestByWord[normalizedSuggestion];
      if (current == null || candidate.score > current.score) {
        bestByWord[normalizedSuggestion] = candidate;
      }
    }

    final ranked =
        bestByWord.values.toList()..sort((left, right) {
          final leftWord = _normalize(left.text);
          final rightWord = _normalize(right.text);
          final leftExactPrefix = leftWord.startsWith(activeWord) ? 1 : 0;
          final rightExactPrefix = rightWord.startsWith(activeWord) ? 1 : 0;
          final prefixOrder = rightExactPrefix.compareTo(leftExactPrefix);
          if (prefixOrder != 0) {
            return prefixOrder;
          }

          final scoreOrder = right.score.compareTo(left.score);
          if (scoreOrder != 0) {
            return scoreOrder;
          }

          final lengthOrder = left.text.length.compareTo(right.text.length);
          if (lengthOrder != 0) {
            return lengthOrder;
          }

          return left.text.compareTo(right.text);
        });

    return ranked.map((candidate) => candidate.text).toList();
  }

  static Map<String, int> _rankedContextIntents({
    required List<String> contextTokens,
    required String languageKey,
  }) {
    final tokenSet = contextTokens.map(_normalize).toSet();
    final keywords =
        _contextCategoryKeywords[languageKey] ??
        _contextCategoryKeywords['english']!;

    final scores = <String, int>{};
    for (final entry in keywords.entries) {
      final shared = tokenSet.intersection(entry.value).length;
      if (shared > 0) {
        scores[entry.key] = (scores[entry.key] ?? 0) + (shared * 120);
      }
    }

    for (final ngram in _ngrams(contextTokens, maxSize: 3)) {
      for (final entry in keywords.entries) {
        for (final keyword in entry.value) {
          if (keyword.length < 4) {
            continue;
          }
          final similarity = _phraseSimilarityScore(ngram, keyword);
          if (similarity >= 78) {
            scores[entry.key] = (scores[entry.key] ?? 0) + 35;
          }
        }
      }
    }

    final rankedEntries =
        scores.entries.toList()
          ..sort((left, right) => right.value.compareTo(left.value));
    return Map.unmodifiable({
      for (final entry in rankedEntries) entry.key: entry.value,
    });
  }

  static int _intentBoostForEntry(
    VocabularyEntry entry,
    Map<String, int> intentScores,
  ) {
    var boost = 0;
    final category = entry.category;
    if (category != null) {
      boost += intentScores[category] ?? 0;
    }

    for (final weight in entry.intentWeights.entries) {
      final contextScore = intentScores[weight.key] ?? 0;
      if (contextScore > 0) {
        boost += ((contextScore * weight.value) / 100).round();
      }
    }

    return boost.clamp(0, 320);
  }

  static int _entryContextBoost(
    VocabularyEntry entry,
    List<String> contextTokens,
  ) {
    if (contextTokens.isEmpty) {
      return 0;
    }

    final contextText = contextTokens.join(' ');
    final normalizedContexts = entry.contexts.map(_normalize);
    var boost = 0;
    for (final context in normalizedContexts) {
      if (context.isEmpty) {
        continue;
      }
      if (contextText.contains(context)) {
        boost += 80;
        continue;
      }
      for (final ngram in _ngrams(contextTokens, maxSize: 3)) {
        if (_phraseSimilarityScore(ngram, context) >= 82) {
          boost += 35;
          break;
        }
      }
    }

    return boost.clamp(0, 180);
  }

  static int _usageBoost(String languageKey, String normalizedWord) {
    final count =
        _acceptedSuggestionCounts['$languageKey|$normalizedWord'] ?? 0;
    return (count * 18).clamp(0, 140);
  }

  static const Map<String, Map<String, Set<String>>> _contextCategoryKeywords =
      {
        'english': {
          'travel': {'where', 'station', 'airport', 'hotel', 'bus', 'train'},
          'food': {'eat', 'drink', 'want', 'order', 'hungry'},
          'shopping': {'buy', 'need', 'price', 'cost', 'pay'},
          'help': {'help', 'emergency', 'lost', 'problem'},
          'greeting': {'hello', 'hi', 'morning', 'evening'},
        },
        'spanish': {
          'travel': {
            'donde',
            'dónde',
            'estacion',
            'estación',
            'aeropuerto',
            'hotel',
            'bus',
            'tren',
          },
          'food': {'comer', 'beber', 'quiero', 'pedir', 'hambre'},
          'shopping': {'comprar', 'necesito', 'precio', 'cuesta', 'pagar'},
          'help': {'ayuda', 'emergencia', 'perdido', 'problema'},
          'greeting': {'hola', 'buenos', 'buenas'},
        },
        'filipino': {
          'travel': {'saan', 'istasyon', 'paliparan', 'hotel', 'bus', 'tren'},
          'food': {'kain', 'inom', 'gusto', 'order', 'gutom'},
          'shopping': {'bili', 'kailangan', 'presyo', 'magkano', 'bayad'},
          'help': {'tulong', 'emergency', 'nawala', 'problema'},
          'greeting': {'kumusta', 'magandang'},
        },
        'japanese': {
          'travel': {'どこ', '駅', '空港', 'ホテル', 'バス', '電車'},
          'food': {'食べたい', '飲みたい', '注文', 'お腹'},
          'shopping': {'買う', '必要', '値段', 'いくら', '支払い'},
          'help': {'助け', '緊急', '迷子', '問題'},
          'greeting': {'こんにちは', 'おはよう', 'こんばんは'},
        },
        'russian': {
          'travel': {'где', 'станция', 'аэропорт', 'отель', 'автобус', 'поезд'},
          'food': {'есть', 'пить', 'хочу', 'заказать', 'голоден'},
          'shopping': {'купить', 'нужно', 'цена', 'стоит', 'платить'},
          'help': {'помощь', 'срочно', 'потерялся', 'проблема'},
          'greeting': {'привет', 'здравствуйте', 'утро', 'вечер'},
        },
      };

  static const Map<String, Set<String>> _keyboardNeighbors = {
    'q': {'w', 'a'},
    'w': {'q', 'e', 'a', 's'},
    'e': {'w', 'r', 's', 'd'},
    'r': {'e', 't', 'd', 'f'},
    't': {'r', 'y', 'f', 'g'},
    'y': {'t', 'u', 'g', 'h'},
    'u': {'y', 'i', 'h', 'j'},
    'i': {'u', 'o', 'j', 'k'},
    'o': {'i', 'p', 'k', 'l'},
    'p': {'o', 'l'},
    'a': {'q', 'w', 's', 'z'},
    's': {'w', 'e', 'a', 'd', 'z', 'x'},
    'd': {'e', 'r', 's', 'f', 'x', 'c'},
    'f': {'r', 't', 'd', 'g', 'c', 'v'},
    'g': {'t', 'y', 'f', 'h', 'v', 'b'},
    'h': {'y', 'u', 'g', 'j', 'b', 'n'},
    'j': {'u', 'i', 'h', 'k', 'n', 'm'},
    'k': {'i', 'o', 'j', 'l', 'm'},
    'l': {'o', 'p', 'k'},
    'z': {'a', 's', 'x'},
    'x': {'z', 's', 'd', 'c'},
    'c': {'x', 'd', 'f', 'v'},
    'v': {'c', 'f', 'g', 'b'},
    'b': {'v', 'g', 'h', 'n'},
    'n': {'b', 'h', 'j', 'm'},
    'm': {'n', 'j', 'k'},
  };

  static bool _isSingleAutocompleteWord(String word) {
    final normalizedWord = _normalize(word);
    return normalizedWord.isNotEmpty && !normalizedWord.contains(' ');
  }

  static bool _isAutocompleteCandidateWord(String word) {
    final normalizedWord = _normalize(word);
    if (!_isSingleAutocompleteWord(normalizedWord)) {
      return false;
    }
    if (RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(normalizedWord)) {
      return normalizedWord.length >= 2;
    }
    return normalizedWord.length >= 5;
  }

  static String _activeWordFrom(String text) {
    final words = text.trimRight().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.last;
  }

  static bool _isCompleteSingleKnownWord({
    required String text,
    required String languageKey,
  }) {
    final words = _wordsBySpace(text);
    if (words.length != 1) {
      return false;
    }

    final normalizedWord = words.single;
    if ((_wordsByLanguage[languageKey] ?? const [])
        .map(_normalize)
        .contains(normalizedWord)) {
      return true;
    }

    final vocabulary = _vocabularyByLanguage[languageKey];
    if (vocabulary == null) {
      return false;
    }

    return vocabulary.searchableEntries().any((entry) {
      return _normalize(entry.word) == normalizedWord ||
          entry.aliases.map(_normalize).contains(normalizedWord);
    });
  }

  static List<String> _orderedTokens(String text) {
    return _normalize(
      text,
    ).split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((token) {
      return token.length > 1 || !_isLatinText(token);
    }).toList();
  }

  static List<String> _wordsBySpace(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static List<String> _ngrams(List<String> tokens, {required int maxSize}) {
    final chunks = <String>[];
    for (var start = 0; start < tokens.length; start++) {
      for (var size = 1; size <= maxSize; size++) {
        final end = start + size;
        if (end > tokens.length) {
          break;
        }
        chunks.add(tokens.sublist(start, end).join(' '));
      }
    }
    return chunks;
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
