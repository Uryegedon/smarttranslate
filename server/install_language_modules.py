from __future__ import annotations

import argparse
import os
from dataclasses import dataclass
from pathlib import Path

SERVER_DIR = Path(__file__).resolve().parent
ARGOS_DIR = SERVER_DIR / ".argos"
os.environ.setdefault("XDG_CONFIG_HOME", str(ARGOS_DIR / "config"))
os.environ.setdefault("XDG_DATA_HOME", str(ARGOS_DIR / "data"))
os.environ.setdefault("XDG_CACHE_HOME", str(ARGOS_DIR / "cache"))
os.environ.setdefault("STANZA_RESOURCES_DIR", str(ARGOS_DIR / "stanza"))

import argostranslate.package
import stanza


DEFAULT_LANGUAGE_CODES = ("en", "es", "tl", "ja", "ru")


@dataclass(frozen=True)
class LanguagePair:
    source: str
    target: str

    @property
    def label(self) -> str:
        return f"{self.source}-{self.target}"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download and install Argos Translate language modules.",
    )
    parser.add_argument(
        "--languages",
        nargs="+",
        default=DEFAULT_LANGUAGE_CODES,
        help="Language codes to install pair modules for. Default: en es tl ja ru",
    )
    args = parser.parse_args()

    language_codes = tuple(dict.fromkeys(code.lower() for code in args.languages))
    requested_pairs = [
        LanguagePair(source, target)
        for source in language_codes
        for target in language_codes
        if source != target
    ]

    print("Updating Argos package index...")
    argostranslate.package.update_package_index()
    available_packages = argostranslate.package.get_available_packages()

    installed: list[str] = []
    missing: list[str] = []

    for pair in requested_pairs:
        package = next(
            (
                item
                for item in available_packages
                if item.from_code == pair.source and item.to_code == pair.target
            ),
            None,
        )

        if package is None:
            missing.append(pair.label)
            continue

        print(f"Installing {pair.label}...")
        package_path = package.download()
        argostranslate.package.install_from_path(package_path)
        installed.append(pair.label)

    if installed:
        print("Installed modules:")
        for pair in installed:
            print(f"- {pair}")

    if missing:
        print("No Argos package found for:")
        for pair in missing:
            print(f"- {pair}")

    print("Installing Stanza sentence-splitting resources...")
    installed_packages = argostranslate.package.get_installed_packages()
    stanza_targets = {
        (package.from_code, package.package_path / "stanza")
        for package in installed_packages
        if package.from_code in language_codes
    }
    for language_code, model_dir in sorted(stanza_targets):
        try:
            stanza.download(
                language_code,
                model_dir=str(model_dir),
                processors="tokenize",
                verbose=False,
            )
            print(f"- {language_code}: {model_dir}")
        except Exception as exc:
            print(f"- {language_code}: unavailable ({exc})")


if __name__ == "__main__":
    main()
