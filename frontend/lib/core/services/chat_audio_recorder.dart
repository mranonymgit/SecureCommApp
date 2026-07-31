import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class RecordedChatAudio {
  const RecordedChatAudio({required this.bytes, required this.duration});

  final Uint8List bytes;
  final Duration duration;
}

class ChatAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _streamCompleted;
  final List<int> _bytes = [];
  DateTime? _startedAt;

  static const int _sampleRate = 44100;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;

  bool get isRecording => _subscription != null;

  Future<void> start() async {
    if (isRecording) return;
    if (!await _recorder.hasPermission()) {
      throw StateError('El permiso del micrófono fue denegado.');
    }
    _bytes.clear();
    _streamCompleted = Completer<void>();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _channels,
      ),
    );
    _subscription = stream.listen(
      _bytes.addAll,
      onDone: () {
        if (!(_streamCompleted?.isCompleted ?? true)) {
          _streamCompleted!.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!(_streamCompleted?.isCompleted ?? true)) {
          _streamCompleted!.completeError(error, stackTrace);
        }
      },
    );
    _startedAt = DateTime.now();
  }

  Future<RecordedChatAudio?> stop() async {
    if (!isRecording) return null;
    final subscription = _subscription!;
    _subscription = null;
    await _recorder.stop();
    Object? streamError;
    StackTrace? streamStackTrace;
    try {
      await _streamCompleted?.future.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Some platform recorders do not close the byte stream explicitly.
    } catch (error, stackTrace) {
      streamError = error;
      streamStackTrace = stackTrace;
    } finally {
      await subscription.cancel();
      _streamCompleted = null;
    }
    if (streamError != null) {
      Error.throwWithStackTrace(streamError, streamStackTrace!);
    }
    final duration = DateTime.now().difference(_startedAt ?? DateTime.now());
    _startedAt = null;
    if (_bytes.isEmpty) return null;
    return RecordedChatAudio(
      bytes: _asWav(Uint8List.fromList(_bytes)),
      duration: duration,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _recorder.dispose();
  }

  Uint8List _asWav(Uint8List pcm) {
    final header = ByteData(44);
    final byteRate = _sampleRate * _channels * _bitsPerSample ~/ 8;
    final blockAlign = _channels * _bitsPerSample ~/ 8;
    void writeAscii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        header.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }
}
