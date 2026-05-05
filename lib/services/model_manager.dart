import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:whisper_ggml/whisper_ggml.dart';

typedef DownloadProgress = void Function(int received, int total);

class ModelManager {
  ModelManager({WhisperModel model = WhisperModel.base}) : _model = model;

  final WhisperModel _model;
  final WhisperController _controller = WhisperController();

  WhisperModel get model => _model;

  Future<String> modelPath() => _controller.getPath(_model);

  Future<bool> isDownloaded() async {
    final path = await modelPath();
    return File(path).existsSync();
  }

  Future<String> ensureModel({DownloadProgress? onProgress}) async {
    final path = await modelPath();
    final file = File(path);
    if (file.existsSync() && await file.length() > 0) {
      return path;
    }

    await file.parent.create(recursive: true);
    final partial = File('$path.part');
    if (partial.existsSync()) {
      await partial.delete();
    }

    final request = http.Request('GET', _model.modelUri);
    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw Exception(
        'Error descargando el modelo (HTTP ${response.statusCode}).',
      );
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = partial.openWrite();
    try {
      await response.stream.listen((chunk) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(received, total);
      }).asFuture<void>();
    } finally {
      await sink.close();
    }

    await partial.rename(path);
    return path;
  }
}
