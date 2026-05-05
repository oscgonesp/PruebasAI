import 'package:whisper_ggml/whisper_ggml.dart';

class TranscriptionService {
  TranscriptionService({WhisperModel model = WhisperModel.base})
      : _model = model;

  final WhisperModel _model;
  final WhisperController _controller = WhisperController();

  Future<String> transcribe(String wavPath, {String language = 'es'}) async {
    final result = await _controller.transcribe(
      model: _model,
      audioPath: wavPath,
      lang: language,
    );

    final text = result?.transcription.text;
    if (text == null) {
      throw Exception(
        'La transcripción falló. Revisa el modelo y el archivo de audio.',
      );
    }
    return text.trim();
  }
}
