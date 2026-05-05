import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class AudioConverter {
  Future<String> toWav16kMono(String inputPath) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/whisper_input_${DateTime.now().millisecondsSinceEpoch}.wav';

    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }

    final converter = WhisperAudioConvert(
      audioInput: File(inputPath),
      audioOutput: outputFile,
    );
    final result = await converter.convert();
    if (result == null) {
      throw Exception(
        'No se pudo convertir el audio. Verifica que el archivo no esté corrupto.',
      );
    }
    return result.path;
  }
}
