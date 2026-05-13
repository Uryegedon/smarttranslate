import json
import os
import re
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

SERVER_DIR = Path(__file__).resolve().parent
DATA_DIR = SERVER_DIR / "data"
PHRASEBANK_PATH = SERVER_DIR / "data" / "phrasebank.json"
TRANSLATION_HISTORY_PATH = DATA_DIR / "translation_history.json"
MAX_TRANSLATION_HISTORY = 500
ARGOS_DIR = SERVER_DIR / ".argos"
os.environ.setdefault("XDG_CONFIG_HOME", str(ARGOS_DIR / "config"))
os.environ.setdefault("XDG_DATA_HOME", str(ARGOS_DIR / "data"))
os.environ.setdefault("XDG_CACHE_HOME", str(ARGOS_DIR / "cache"))
os.environ.setdefault("STANZA_RESOURCES_DIR", str(ARGOS_DIR / "stanza"))

try:
    import argostranslate.translate
except ImportError:  # Online fallback can still run without local modules.
    argostranslate = None

try:
    import argostranslate.package
except ImportError:
    argos_package = None
else:
    argos_package = argostranslate.package

try:
    from deep_translator import GoogleTranslator
except ImportError:  # Keeps startup error readable if requirements were skipped.
    GoogleTranslator = None


app = FastAPI(title="SmartPath Translation API")
cors_origins = [
    origin.strip()
    for origin in os.environ.get("TRANSLATION_CORS_ORIGINS", "*").split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
_ARGOS_LANGUAGE_CACHE = None
_PHRASEBANK = None
ALLOW_ONLINE_FALLBACK = os.environ.get(
    "TRANSLATION_ALLOW_ONLINE_FALLBACK",
    "true",
).strip().lower() not in {"0", "false", "no", "off"}

LANGUAGE_CODES = {
    "auto": "auto",
    "english": "en",
    "spanish": "es",
    "filipino": "tl",
    "japanese": "ja",
    "russian": "ru",
}


class TranslateRequest(BaseModel):
    text: str
    source_language: str | None = "Auto"
    target_language: str | None = "English"
    record: bool | None = True


class TranslateBatchRequest(BaseModel):
    items: list[TranslateRequest]


class AlternativesRequest(BaseModel):
    text: str
    source_language: str | None = "English"
    target_language: str | None = "English"
    translated_text: str | None = None
    limit: int | None = 3


class TranslationHistoryRecordRequest(BaseModel):
    text: str
    translated_text: str
    source_language: str | None = "English"
    target_language: str | None = "English"


class OfflineModuleInstallRequest(BaseModel):
    source_language: str | None = None
    target_language: str | None = None
    include_reverse: bool = False
    all_app_languages: bool = False


@app.get("/health")
def health():
    return {
        "status": "ok",
        "offline_translation": _installed_argos_pairs(),
        "online_fallback_enabled": ALLOW_ONLINE_FALLBACK,
        "cors_origins": cors_origins or ["*"],
        "phrasebank_concepts": len(_load_phrasebank()),
        "translation_history_entries": len(_load_translation_history()),
    }


@app.get("/offline-modules/")
def offline_modules():
    installed_pairs = _installed_argos_pairs()
    app_pairs = _app_language_pairs()

    return {
        "languages": {
            name.title(): code
            for name, code in LANGUAGE_CODES.items()
            if name != "auto"
        },
        "installed_pairs": installed_pairs,
        "missing_pairs": [
            pair for pair in app_pairs if pair not in installed_pairs
        ],
    }


@app.post("/offline-modules/install")
def install_offline_modules(request: OfflineModuleInstallRequest):
    if argos_package is None:
        raise HTTPException(
            status_code=500,
            detail="Argos package tools are not installed. Run pip install -r requirements.txt.",
        )

    target_pairs = _requested_install_pairs(request)
    if not target_pairs:
        raise HTTPException(status_code=400, detail="No language pair selected.")

    try:
        argos_package.update_package_index()
        available_packages = argos_package.get_available_packages()
        installed_packages = argos_package.get_installed_packages()
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Argos package index failed: {exc}") from exc

    installed_package_pairs = {
        f"{package.from_code}-{package.to_code}"
        for package in installed_packages
    }
    required_package_pairs = _required_package_pairs(target_pairs, available_packages)

    installed: list[str] = []
    skipped: list[str] = []
    missing: list[str] = []

    for pair in sorted(required_package_pairs):
        source_code, target_code = pair.split("-", maxsplit=1)
        if pair in installed_package_pairs:
            skipped.append(pair)
            continue

        package = next(
            (
                item
                for item in available_packages
                if item.from_code == source_code and item.to_code == target_code
            ),
            None,
        )
        if package is None:
            missing.append(pair)
            continue

        try:
            package_path = package.download()
            argos_package.install_from_path(package_path)
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f"Installing {pair} failed: {exc}") from exc

        installed.append(pair)
        installed_package_pairs.add(pair)

    _clear_argos_language_cache()

    return {
        "installed": installed,
        "skipped": skipped,
        "missing": missing,
        "offline_translation": _installed_argos_pairs(),
    }


@app.post("/translate/")
def translate(request: TranslateRequest):
    translated_text, provider = _translate_with_provider(
        text=request.text,
        source_language=request.source_language,
        target_language=request.target_language,
    )
    if request.record:
        _record_translation(
            source_text=request.text,
            translated_text=translated_text,
            source_language=request.source_language,
            target_language=request.target_language,
        )

    return {
        "translated_text": translated_text,
        "provider": provider,
    }


@app.post("/translate/batch/")
def translate_batch(request: TranslateBatchRequest):
    if len(request.items) > 150:
        raise HTTPException(status_code=400, detail="Batch size is limited to 150 items.")

    translations = []
    for item in request.items:
        try:
            translated_text, provider = _translate_with_provider(
                text=item.text,
                source_language=item.source_language,
                target_language=item.target_language,
            )
            if item.record:
                _record_translation(
                    source_text=item.text,
                    translated_text=translated_text,
                    source_language=item.source_language,
                    target_language=item.target_language,
                )

            translations.append(
                {
                    "translated_text": translated_text,
                    "provider": provider,
                }
            )
        except HTTPException as exc:
            translations.append(
                {
                    "translated_text": None,
                    "error": str(exc.detail),
                }
            )

    return {"translations": translations}


@app.post("/translation-history/")
def record_translation_history(request: TranslationHistoryRecordRequest):
    _record_translation(
        source_text=request.text,
        translated_text=request.translated_text,
        source_language=request.source_language,
        target_language=request.target_language,
    )
    return {
        "stored": True,
        "translation_history_entries": len(_load_translation_history()),
    }


@app.get("/game-words/")
def game_words(languages: str | None = None, limit: int = 18):
    requested_languages = _requested_game_languages(languages)
    max_base_words = max(1, min(limit, 100))
    history = _load_translation_history()

    words: list[dict] = []
    used_base_words: set[str] = set()
    for entry in reversed(history):
        base_word = entry.get("base_word")
        translations = entry.get("translations", {})
        if not isinstance(base_word, str) or not isinstance(translations, dict):
            continue

        cleaned_base_word = _clean_game_word(base_word)
        if not cleaned_base_word or cleaned_base_word.lower() in used_base_words:
            continue

        entry_words = []
        for language in requested_languages:
            translation = translations.get(_normalize_language(language, fallback=""))
            cleaned_translation = _clean_game_word(translation)
            if not cleaned_translation:
                continue

            entry_words.append(
                {
                    "base_word": cleaned_base_word,
                    "language": language,
                    "word": cleaned_translation,
                }
            )

        if entry_words:
            used_base_words.add(cleaned_base_word.lower())
            words.extend(entry_words)

        if len(used_base_words) >= max_base_words:
            break

    return {"words": words}


@app.post("/alternatives/")
def alternatives(request: AlternativesRequest):
    target_language = _normalize_language(
        request.target_language,
        fallback="english",
    )
    if target_language == "auto":
        raise HTTPException(status_code=400, detail="Target language cannot be Auto.")

    match = _best_phrasebank_match(
        text=request.text,
        source_language=_normalize_language(
            request.source_language,
            fallback="auto",
        ),
        target_language=target_language,
    )
    if match is None:
        return {
            "matched_concept": None,
            "intent": None,
            "score": 0,
            "alternatives": [],
        }

    concept, score = match
    translations = concept.get("translations", {})
    candidates = translations.get(target_language, [])
    alternatives = _unique_texts(
        candidates,
        exclude={
            request.text,
            request.translated_text or "",
        },
        limit=max(1, min(request.limit or 3, 10)),
    )

    return {
        "matched_concept": concept.get("id"),
        "intent": concept.get("intent"),
        "score": score,
        "alternatives": alternatives,
    }


def _translate_text(
    text: str,
    source_language: str | None,
    target_language: str | None,
) -> str:
    translated_text, _ = _translate_with_provider(
        text=text,
        source_language=source_language,
        target_language=target_language,
    )
    return translated_text


def _translate_with_provider(
    text: str,
    source_language: str | None,
    target_language: str | None,
) -> tuple[str, str]:
    text = text.strip()
    if not text:
        return "", "empty"

    source_language = _normalize_language(source_language, fallback="auto")
    target_language = _normalize_language(target_language, fallback="english")

    if source_language == target_language:
        return text, "identity"

    offline_translation = _translate_with_argos(
        text=text,
        source_language=source_language,
        target_language=target_language,
    )
    if offline_translation is not None:
        return offline_translation, "argos"

    if not ALLOW_ONLINE_FALLBACK:
        raise HTTPException(
            status_code=424,
            detail="No offline translation module is installed for this language pair.",
        )

    if GoogleTranslator is None:
        raise HTTPException(
            status_code=500,
            detail=(
                "No offline translation module is installed for this language pair, "
                "and deep-translator is not installed. Run pip install -r requirements.txt."
            ),
        )

    try:
        translated = GoogleTranslator(
            source=LANGUAGE_CODES[source_language],
            target=LANGUAGE_CODES[target_language],
        ).translate(text)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Translation provider failed: {exc}") from exc

    if not translated:
        raise HTTPException(status_code=502, detail="Translation provider returned no text.")

    return translated, "google"


def _load_translation_history() -> list[dict]:
    if not TRANSLATION_HISTORY_PATH.exists():
        return []

    try:
        with TRANSLATION_HISTORY_PATH.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except (json.JSONDecodeError, OSError):
        return []

    return data if isinstance(data, list) else []


def _save_translation_history(history: list[dict]):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with TRANSLATION_HISTORY_PATH.open("w", encoding="utf-8") as file:
        json.dump(
            history[-MAX_TRANSLATION_HISTORY:],
            file,
            ensure_ascii=False,
            indent=2,
        )


def _record_translation(
    source_text: str,
    translated_text: str,
    source_language: str | None,
    target_language: str | None,
):
    source_key = _normalize_language(source_language, fallback="auto")
    target_key = _normalize_language(target_language, fallback="english")
    if (
        not source_text.strip()
        or not translated_text.strip()
        or source_key in {"", "auto"}
        or target_key in {"", "auto"}
        or source_key == target_key
    ):
        return

    if source_key == "english":
        base_word = source_text.strip()
        translation_language = target_key
        translation_text = translated_text.strip()
    elif target_key == "english":
        base_word = translated_text.strip()
        translation_language = source_key
        translation_text = source_text.strip()
    else:
        return

    if not _is_game_sized_text(base_word) or not _is_game_sized_text(translation_text):
        return

    history = _load_translation_history()
    normalized_base_word = _normalize_text(base_word)
    existing = next(
        (
            entry
            for entry in history
            if _normalize_text(entry.get("base_word")) == normalized_base_word
        ),
        None,
    )

    if existing is None:
        existing = {
            "base_word": base_word,
            "translations": {},
            "uses": 0,
        }
        history.append(existing)

    translations = existing.setdefault("translations", {})
    if isinstance(translations, dict):
        translations[translation_language] = translation_text
    existing["uses"] = int(existing.get("uses") or 0) + 1

    _save_translation_history(history)


def _requested_game_languages(languages: str | None) -> list[str]:
    supported = {
        language.title(): key
        for key, language in {
            "english": "English",
            "spanish": "Spanish",
            "filipino": "Filipino",
            "japanese": "Japanese",
            "russian": "Russian",
        }.items()
    }
    if not languages:
        return list(supported.keys())

    requested = []
    for language in languages.split(","):
        display_name = language.strip().title()
        if display_name in supported and display_name not in requested:
            requested.append(display_name)

    return requested or list(supported.keys())


def _clean_game_word(value: str | None) -> str:
    return re.sub(r"[.!?]+$", "", (value or "").strip())


def _is_game_sized_text(value: str) -> bool:
    words = [word for word in re.split(r"\s+", value.strip()) if word]
    return 1 <= len(words) <= 6 and len(value.strip()) <= 80


def _load_phrasebank() -> list[dict]:
    global _PHRASEBANK
    if _PHRASEBANK is not None:
        return _PHRASEBANK

    if not PHRASEBANK_PATH.exists():
        _PHRASEBANK = []
        return _PHRASEBANK

    with PHRASEBANK_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)

    if not isinstance(data, list):
        raise RuntimeError("Phrasebank must be a JSON list.")

    _PHRASEBANK = [
        concept
        for concept in data
        if isinstance(concept, dict) and isinstance(concept.get("translations"), dict)
    ]
    return _PHRASEBANK


def _best_phrasebank_match(
    text: str,
    source_language: str,
    target_language: str,
) -> tuple[dict, int] | None:
    normalized_text = _normalize_text(text)
    if not normalized_text:
        return None

    best_concept = None
    best_score = 0
    for concept in _load_phrasebank():
        translations = concept.get("translations", {})
        source_phrases = _source_phrases_for_match(
            translations=translations,
            source_language=source_language,
            target_language=target_language,
        )
        for phrase in source_phrases:
            score = _phrase_similarity_score(normalized_text, phrase)
            if not _is_plausible_phrase_match(normalized_text, phrase, score):
                continue
            if score > best_score:
                best_score = score
                best_concept = concept

    if best_concept is None or best_score < 72:
        return None

    return best_concept, best_score


def _source_phrases_for_match(
    translations: dict,
    source_language: str,
    target_language: str,
) -> list[str]:
    if source_language != "auto":
        phrases = translations.get(source_language, [])
        return phrases if isinstance(phrases, list) else []

    phrases: list[str] = []
    for language, values in translations.items():
        if language == target_language or not isinstance(values, list):
            continue
        phrases.extend(values)
    return phrases


def _phrase_similarity_score(text: str, phrase: str) -> int:
    normalized_phrase = _normalize_text(phrase)
    if not normalized_phrase:
        return 0
    if text == normalized_phrase:
        return 100

    text_tokens = _tokens(text)
    phrase_tokens = _tokens(normalized_phrase)
    token_score = 0
    if text_tokens and phrase_tokens:
        shared_tokens = len(text_tokens.intersection(phrase_tokens))
        smaller_token_count = min(len(text_tokens), len(phrase_tokens))
        token_score = round(shared_tokens / smaller_token_count * 100)

    max_length = max(len(text), len(normalized_phrase))
    edit_score = round(
        (1 - (_levenshtein_distance(text, normalized_phrase) / max_length)) * 100
    )
    contains_score = 90 if text in normalized_phrase or normalized_phrase in text else 0
    return max(token_score, edit_score, contains_score)


def _is_plausible_phrase_match(text: str, phrase: str, score: int) -> bool:
    normalized_phrase = _normalize_text(phrase)
    if (
        text == normalized_phrase
        or text.startswith(normalized_phrase)
        or normalized_phrase.startswith(text)
        or text in normalized_phrase
        or normalized_phrase in text
    ):
        return True

    if _meaningful_tokens(text).intersection(_meaningful_tokens(normalized_phrase)):
        return True

    return score >= 84


def _meaningful_tokens(text: str) -> set[str]:
    return {token for token in _tokens(text) if token not in FUZZY_PHRASE_STOP_WORDS}


FUZZY_PHRASE_STOP_WORDS = {
    "a",
    "an",
    "and",
    "are",
    "can",
    "could",
    "did",
    "does",
    "he",
    "i",
    "is",
    "it",
    "me",
    "my",
    "of",
    "say",
    "she",
    "the",
    "this",
    "to",
    "what",
    "where",
    "who",
    "why",
    "you",
}


def _levenshtein_distance(first: str, second: str) -> int:
    rows = len(first) + 1
    columns = len(second) + 1
    table = [[0] * columns for _ in range(rows)]

    for row in range(rows):
        table[row][0] = row
    for column in range(columns):
        table[0][column] = column

    for row in range(1, rows):
        for column in range(1, columns):
            cost = 0 if first[row - 1] == second[column - 1] else 1
            table[row][column] = min(
                table[row - 1][column] + 1,
                table[row][column - 1] + 1,
                table[row - 1][column - 1] + cost,
            )

    return table[-1][-1]


def _tokens(text: str) -> set[str]:
    return {
        token
        for token in re.split(r"[^\w]+", _normalize_text(text), flags=re.UNICODE)
        if len(token) > 1
    }


def _unique_texts(
    candidates: list[str],
    exclude: set[str],
    limit: int,
) -> list[str]:
    excluded = {_normalize_text(item) for item in exclude if item}
    seen: set[str] = set()
    results: list[str] = []
    for candidate in candidates:
        normalized = _normalize_text(candidate)
        if not normalized or normalized in excluded or normalized in seen:
            continue
        seen.add(normalized)
        results.append(candidate)
        if len(results) >= limit:
            break
    return results


def _normalize_text(text: str | None) -> str:
    return re.sub(r"\s+", " ", (text or "").strip().lower())


def _normalize_language(value: str | None, fallback: str) -> str:
    language = (value or fallback).strip().lower()
    return language if language in LANGUAGE_CODES else fallback


def _translate_with_argos(
    text: str,
    source_language: str,
    target_language: str,
) -> str | None:
    if argostranslate is None or source_language == "auto":
        return None

    source_code = LANGUAGE_CODES[source_language]
    target_code = LANGUAGE_CODES[target_language]

    try:
        installed_languages = _installed_argos_languages()
        source = next(
            (language for language in installed_languages if language.code == source_code),
            None,
        )
        target = next(
            (language for language in installed_languages if language.code == target_code),
            None,
        )
        if source is None or target is None:
            return None

        direct_translation = _argos_translate_between(
            text=text,
            source=source,
            target=target,
        )
        if direct_translation:
            return direct_translation

        if source_code != "en" and target_code != "en":
            english = next(
                (language for language in installed_languages if language.code == "en"),
                None,
            )
            if english is None:
                return None

            pivot_text = _argos_translate_between(
                text=text,
                source=source,
                target=english,
            )
            if not pivot_text:
                return None

            return _argos_translate_between(
                text=pivot_text,
                source=english,
                target=target,
            )
    except Exception:
        return None

    return None


def _argos_translate_between(text: str, source, target) -> str | None:
    translation = source.get_translation(target)
    if translation is None:
        return None

    translated = translation.translate(text)
    return translated or None


def _installed_argos_pairs() -> list[str]:
    if argostranslate is None:
        return []

    try:
        installed_languages = _installed_argos_languages()
    except Exception:
        return []

    pairs: list[str] = []
    for source in installed_languages:
        for target in installed_languages:
            if source.code == target.code:
                continue
            try:
                if source.get_translation(target) is not None:
                    pairs.append(f"{source.code}-{target.code}")
            except Exception:
                continue

    return sorted(set(pairs))


def _installed_argos_languages():
    global _ARGOS_LANGUAGE_CACHE
    if _ARGOS_LANGUAGE_CACHE is None:
        _ARGOS_LANGUAGE_CACHE = argostranslate.translate.get_installed_languages()
    return _ARGOS_LANGUAGE_CACHE


def _clear_argos_language_cache():
    global _ARGOS_LANGUAGE_CACHE
    _ARGOS_LANGUAGE_CACHE = None


def _app_language_pairs() -> list[str]:
    codes = [
        code for language, code in LANGUAGE_CODES.items()
        if language != "auto"
    ]
    return [
        f"{source}-{target}"
        for source in codes
        for target in codes
        if source != target
    ]


def _requested_install_pairs(request: OfflineModuleInstallRequest) -> set[str]:
    if request.all_app_languages:
        return set(_app_language_pairs())

    source_language = _normalize_language(request.source_language, fallback="")
    target_language = _normalize_language(request.target_language, fallback="")
    if (
        source_language not in LANGUAGE_CODES
        or target_language not in LANGUAGE_CODES
        or source_language in {"", "auto"}
        or target_language in {"", "auto"}
        or source_language == target_language
    ):
        return set()

    source_code = LANGUAGE_CODES[source_language]
    target_code = LANGUAGE_CODES[target_language]
    pairs = {f"{source_code}-{target_code}"}
    if request.include_reverse:
        pairs.add(f"{target_code}-{source_code}")
    return pairs


def _required_package_pairs(target_pairs: set[str], available_packages) -> set[str]:
    available_pairs = {
        f"{package.from_code}-{package.to_code}"
        for package in available_packages
    }

    required: set[str] = set()
    for pair in target_pairs:
        source_code, target_code = pair.split("-", maxsplit=1)
        if pair in available_pairs:
            required.add(pair)
            continue

        if source_code != "en" and target_code != "en":
            required.add(f"{source_code}-en")
            required.add(f"en-{target_code}")
            continue

        required.add(pair)

    return required
