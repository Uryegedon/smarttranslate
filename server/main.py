import os
from pathlib import Path

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

SERVER_DIR = Path(__file__).resolve().parent
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
_ARGOS_LANGUAGE_CACHE = None

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


class TranslateBatchRequest(BaseModel):
    items: list[TranslateRequest]


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
    return {
        "translated_text": _translate_text(
            text=request.text,
            source_language=request.source_language,
            target_language=request.target_language,
        )
    }


@app.post("/translate/batch/")
def translate_batch(request: TranslateBatchRequest):
    if len(request.items) > 150:
        raise HTTPException(status_code=400, detail="Batch size is limited to 150 items.")

    translations = []
    for item in request.items:
        try:
            translations.append(
                {
                    "translated_text": _translate_text(
                        text=item.text,
                        source_language=item.source_language,
                        target_language=item.target_language,
                    )
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


def _translate_text(
    text: str,
    source_language: str | None,
    target_language: str | None,
) -> str:
    text = text.strip()
    if not text:
        return ""

    source_language = _normalize_language(source_language, fallback="auto")
    target_language = _normalize_language(target_language, fallback="english")

    if source_language == target_language:
        return text

    offline_translation = _translate_with_argos(
        text=text,
        source_language=source_language,
        target_language=target_language,
    )
    if offline_translation is not None:
        return offline_translation

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

    return translated


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

        translation = source.get_translation(target)
        if translation is None:
            return None

        translated = translation.translate(text)
    except Exception:
        return None

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
