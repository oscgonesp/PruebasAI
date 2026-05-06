import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_converter.dart';
import '../services/export_service.dart';
import '../services/model_manager.dart';
import '../services/transcription_service.dart';

enum _Stage { idle, downloadingModel, converting, transcribing, done, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ModelManager _modelManager = ModelManager();
  final AudioConverter _converter = AudioConverter();
  final TranscriptionService _transcriber = TranscriptionService();
  final ExportService _exporter = ExportService();

  _Stage _stage = _Stage.idle;
  double? _progress;
  String? _selectedFileName;
  String _transcript = '';
  String? _errorMessage;
  Duration? _elapsed;

  bool get _busy =>
      _stage == _Stage.downloadingModel ||
      _stage == _Stage.converting ||
      _stage == _Stage.transcribing;

  Future<void> _pickAndTranscribe() async {
    setState(() {
      _errorMessage = null;
      _transcript = '';
      _elapsed = null;
    });

    XFile? picked;
    try {
      picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'audio', mimeTypes: ['audio/*']),
        ],
      );
    } catch (e) {
      _setError('No se pudo abrir el selector de archivos: $e');
      return;
    }
    if (picked == null) return;

    final path = picked.path;
    setState(() {
      _selectedFileName = picked!.name;
    });

    final stopwatch = Stopwatch()..start();
    String? wavPath;
    try {
      if (!await _modelManager.isDownloaded()) {
        setState(() {
          _stage = _Stage.downloadingModel;
          _progress = 0;
        });
        await _modelManager.ensureModel(
          onProgress: (received, total) {
            if (!mounted) return;
            setState(() {
              _progress = total > 0 ? received / total : null;
            });
          },
        );
      }

      setState(() {
        _stage = _Stage.converting;
        _progress = null;
      });
      wavPath = await _converter.toWav16kMono(path);

      setState(() => _stage = _Stage.transcribing);
      final text = await _transcriber.transcribe(wavPath, language: 'es');

      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _transcript = text;
        _stage = _Stage.done;
        _elapsed = stopwatch.elapsed;
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (wavPath != null) {
        final f = File(wavPath);
        if (f.existsSync()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.error;
      _errorMessage = message;
      _progress = null;
    });
  }

  Future<void> _copyTranscript() async {
    await Clipboard.setData(ClipboardData(text: _transcript));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcripción copiada al portapapeles')),
    );
  }

  Future<void> _exportTxt() async {
    try {
      await _exporter.saveAndShare(
        _transcript,
        originalFileName: _selectedFileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  String _stageLabel() {
    switch (_stage) {
      case _Stage.idle:
        return 'Selecciona un archivo de audio para empezar.';
      case _Stage.downloadingModel:
        final pct = _progress;
        return pct != null
            ? 'Descargando modelo Whisper (${(pct * 100).toStringAsFixed(0)} %)...'
            : 'Descargando modelo Whisper...';
      case _Stage.converting:
        return 'Convirtiendo audio a WAV 16 kHz...';
      case _Stage.transcribing:
        return 'Transcribiendo (esto puede tardar varios minutos)...';
      case _Stage.done:
        final secs = _elapsed?.inSeconds ?? 0;
        return 'Transcripción lista en ${secs}s.';
      case _Stage.error:
        return 'Error: ${_errorMessage ?? "desconocido"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PruebasAI · Transcripción local'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _pickAndTranscribe,
                icon: const Icon(Icons.audio_file),
                label: const Text('Seleccionar audio y transcribir'),
              ),
              const SizedBox(height: 12),
              if (_selectedFileName != null)
                Text(
                  'Archivo: $_selectedFileName',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Text(_stageLabel(), style: theme.textTheme.bodyMedium),
              if (_busy) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _progress),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _transcript.isEmpty
                          ? 'La transcripción aparecerá aquí.'
                          : _transcript,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _transcript.isEmpty ? null : _copyTranscript,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _transcript.isEmpty ? null : _exportTxt,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Exportar TXT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
