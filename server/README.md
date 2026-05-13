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

The alternatives endpoint reads `server/data/phrasebank.json` and returns
contextual alternatives from concept IDs and intents:

```powershell
Invoke-RestMethod `
  -Uri http://127.0.0.1:8000/alternatives/ `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"text":"where bathroom","source_language":"English","target_language":"Japanese","translated_text":"トイレはどこですか"}'
```

Expected shape:

```json
{
  "matched_concept": "travel.where_bathroom",
  "intent": "directions",
  "score": 100,
  "alternatives": ["お手洗いはどこですか", "トイレはありますか"]
}
```

Successful `/translate/` calls are also recorded into
`server/data/translation_history.json`. The Flutter mini-games call
`/game-words/` first, so recently translated English-based words and phrases
become the preferred vocabulary source. If the history is empty or the server is
unavailable, the app falls back to its bundled dictionary.

```powershell
Invoke-RestMethod `
  -Uri "http://127.0.0.1:8000/game-words/?languages=Spanish,Japanese&limit=10"
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

Ngrok from this machine:

```powershell
ngrok http 8000

flutter run --dart-define=TRANSLATION_API_URL=https://YOUR_NGROK_HOST.ngrok-free.app/translate/
```

The app's Profile > Offline Downloads > Translation Server dialog also accepts
just the ngrok code, for example `abc123`, and expands it to the full
`https://abc123.ngrok-free.app/translate/` URL.

The server tries local Argos modules first. If a pair is missing, it falls back
to the online translator by default and includes a `provider` field such as
`argos`, `google`, or `identity` in translation responses. To require local
modules only:

```powershell
$env:TRANSLATION_ALLOW_ONLINE_FALLBACK = "false"
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Filipino offline TTS

The app supports Filipino offline TTS through a sherpa-onnx-compatible MMS VITS
archive. Sherpa-onnx does not currently publish a prebuilt `vits-mms-tgl`
archive, so convert `facebook/mms-tts-tgl` to sherpa-onnx format first, host the
resulting `.tar.bz2`, then pass its URL when building or running Flutter:

```powershell
flutter run `
  --dart-define=TRANSLATION_API_URL=http://10.0.2.2:8000/translate/ `
  --dart-define=FILIPINO_TTS_ARCHIVE_URL=https://YOUR_HOST/vits-mms-tgl.tar.bz2
```

The archive should contain the converted MMS files:

```text
vits-mms-tgl/
  model.onnx
  tokens.txt
```
