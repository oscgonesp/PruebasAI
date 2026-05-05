import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class AudioConverter {
  Future<String> toWav16kMono(String inputPath) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/whisper_input_${DateTime.now().millisecondsSinceEpoch}.wav';

    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }

    final command =
        '-y -i "$inputPath" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getOutput();
      throw Exception(
        'FFmpeg no pudo convertir el audio.\n${logs ?? "Sin logs disponibles."}',
      );
    }

    return outputPath;
  }
}
