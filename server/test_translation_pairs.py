import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

import main


class FakeTranslation:
    def __init__(self, values):
        self._values = values

    def translate(self, text):
        return self._values.get(text, "")


class FakeLanguage:
    def __init__(self, code, translations):
        self.code = code
        self._translations = translations

    def get_translation(self, target):
        return self._translations.get(target.code)


class TranslationPairTests(unittest.TestCase):
    def setUp(self):
        self.previous_argostranslate = main.argostranslate
        self.previous_cache = main._ARGOS_LANGUAGE_CACHE
        main.argostranslate = object()

    def tearDown(self):
        main.argostranslate = self.previous_argostranslate
        main._ARGOS_LANGUAGE_CACHE = self.previous_cache

    def test_direct_spanish_to_english_pair_works(self):
        spanish = FakeLanguage("es", {"en": FakeTranslation({"hola": "hello"})})
        english = FakeLanguage("en", {})
        main._ARGOS_LANGUAGE_CACHE = [spanish, english]

        translated = main._translate_with_argos(
            text="hola",
            source_language="spanish",
            target_language="english",
        )

        self.assertEqual(translated, "hello")

    def test_non_english_pair_pivots_through_english(self):
        spanish = FakeLanguage("es", {"en": FakeTranslation({"hola": "hello"})})
        english = FakeLanguage("en", {"tl": FakeTranslation({"hello": "kumusta"})})
        filipino = FakeLanguage("tl", {})
        main._ARGOS_LANGUAGE_CACHE = [spanish, english, filipino]

        translated = main._translate_with_argos(
            text="hola",
            source_language="spanish",
            target_language="filipino",
        )

        self.assertEqual(translated, "kumusta")

    def test_phrasebank_does_not_match_unrelated_question_to_help(self):
        match = main._best_phrasebank_match(
            text="what did he say",
            source_language="english",
            target_language="spanish",
        )

        self.assertIsNone(match)

    def test_phrasebank_still_matches_real_help_request(self):
        match = main._best_phrasebank_match(
            text="can you help me",
            source_language="english",
            target_language="spanish",
        )

        self.assertIsNotNone(match)
        concept, _ = match
        self.assertEqual(concept["id"], "help.can_you_help")

    def test_phrasebank_matches_new_frequent_repeat_phrase(self):
        match = main._best_phrasebank_match(
            text="please repeat that",
            source_language="english",
            target_language="spanish",
        )

        self.assertIsNotNone(match)
        concept, _ = match
        self.assertEqual(concept["id"], "clarification.repeat_that")


if __name__ == "__main__":
    unittest.main()
