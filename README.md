# PruebasAI

App Android escrita en Flutter que toma un archivo de audio local (`.m4a`, `.mp3`, `.wav`, ...) y genera la transcripción **en español** usando [whisper.cpp](https://github.com/ggerganov/whisper.cpp) embebido en el dispositivo. Sin claves de API, sin servidores: la transcripción ocurre 100% en local.

## Cómo funciona

1. El usuario selecciona un archivo de audio con el picker del sistema (SAF).
2. **FFmpeg** (`ffmpeg_kit_flutter_new`) reescala el audio a `WAV mono 16 kHz`, que es el formato que espera whisper.cpp.
3. La primera vez, la app descarga el modelo `ggml-base.bin` (~142 MB) desde Hugging Face a `getApplicationSupportDirectory()`. Las siguientes ejecuciones lo reutilizan.
4. `whisper_ggml` ejecuta whisper.cpp vía FFI con `lang: 'es'` y devuelve el texto.
5. El usuario puede **copiar** o **exportar a TXT** (con share sheet) la transcripción.

## Estructura

```
lib/
├── main.dart                          # bootstrap MaterialApp
├── screens/home_screen.dart           # UI + máquina de estados
└── services/
    ├── model_manager.dart             # descarga del modelo GGML con progreso
    ├── audio_converter.dart           # m4a/etc → WAV 16 kHz mono via FFmpeg
    ├── transcription_service.dart     # wrapper sobre whisper_ggml
    └── export_service.dart            # guarda .txt y abre share sheet
```

## Requisitos de desarrollo

- Flutter ≥ 3.41 (Dart 3.11)
- Android Studio o `cmdline-tools` con plataforma SDK 35
- NDK `29.0.13113456` (lo instala Android Studio bajo demanda)
- JDK 17

## Build

```bash
flutter pub get
flutter run                  # debug en dispositivo conectado
flutter build apk --release  # APK firmado con clave de debug
flutter build apk --split-per-abi --release  # APKs por ABI (más pequeños)
```

El APK debug incluye sólo el código de la app; el modelo (~142 MB) se descarga en el primer arranque.

## Permisos

- `INTERNET` — sólo para descargar el modelo la primera vez.
- `READ_MEDIA_AUDIO` (Android 13+) / `READ_EXTERNAL_STORAGE` (≤ Android 12) — para acceder al audio seleccionado.

## Modelos alternativos

`ModelManager` está parametrizado con `WhisperModel.base`. Para mejor calidad cambia a `WhisperModel.small` (~466 MB) o más pequeño con `WhisperModel.tiny` (~75 MB) en `lib/services/model_manager.dart` y `lib/services/transcription_service.dart`. También puedes precolocar manualmente un modelo cuantizado (`ggml-base-q5_1.bin`) en la ruta que devuelve `WhisperController.getPath(WhisperModel.base)` con el nombre exacto `ggml-base.bin`.

## Limitaciones conocidas

- El motor whisper.cpp es CPU-only en este plugin: en gama baja la transcripción puede tardar 1-2× la duración del audio.
- Audios muy largos (>30 min) consumen RAM significativa durante la conversión y la transcripción.
- El idioma está fijado a español (`'es'`); cambiar en `home_screen.dart` (`language: 'es'`).
