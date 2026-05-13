# SmartPath Translation Server

This server matches the Flutter translator contract in `lib/screens/translationservice.dart`.

## Setup

```powershell
cd F:\smartpath\smarttranslate\server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python install_language_modules.py
uvicorn main:app --host 0.0.0.0 --port 8000
```

`install_language_modules.py` downloads Argos Translate modules for the app
languages: English, Spanish, Filipino/Tagalog, Japanese, and Russian. Argos only installs
language pairs that exist in its package index; unsupported pairs are listed at
the end of the command.

The translator UI posts translation requests to this server instead of using
the app dictionary as the main translation source. The server uses local Argos
modules first. If a pair is not installed or not available, it falls back to
`deep-translator`. If both paths fail, the server returns an error response.

## Test

```powershell
Invoke-RestMethod `
  -Uri http://127.0.0.1:8000/translate/ `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"text":"hello","source_language":"English","target_language":"Spanish"}'
```

Expected response:

```json
{"translated_text":"hola"}
```

Supported app languages:

- English
- Spanish
- Filipino
- Japanese
- Russian

Check installed server-side Argos translation pairs:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

These endpoints still manage server-side Argos packages directly:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/offline-modules/

Invoke-RestMethod `
  -Uri http://127.0.0.1:8000/offline-modules/install `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"source_language":"Russian","target_language":"Japanese","include_reverse":true}'
```

The Flutter app's Profile > Offline Downloads screen now manages **phone-side**
ML Kit translation language models instead. Those downloads make the app capable
of true offline translation on the device after the language models are stored
locally.

## Flutter URL

Android emulator:

```powershell
flutter run --dart-define=TRANSLATION_API_URL=http://10.0.2.2:8000/translate/
```

Physical phone:

```powershell
flutter run --dart-define=TRANSLATION_API_URL=http://YOUR_PC_IP:8000/translate/
```
