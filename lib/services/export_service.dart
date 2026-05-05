import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<File> saveTxt(String text, {String? originalFileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final base = originalFileName != null
        ? _sanitize(_stripExtension(originalFileName))
        : 'transcripcion';
    final file = File('${dir.path}/${base}_$timestamp.txt');
    await file.writeAsString(text);
    return file;
  }

  Future<ShareResult> share(File file, {String? subject}) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject ?? 'Transcripción',
        text: 'Transcripción generada con PruebasAI',
      ),
    );
  }

  Future<File> saveAndShare(String text, {String? originalFileName}) async {
    final file = await saveTxt(text, originalFileName: originalFileName);
    await share(file, subject: 'Transcripción de ${originalFileName ?? "audio"}');
    return file;
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}
