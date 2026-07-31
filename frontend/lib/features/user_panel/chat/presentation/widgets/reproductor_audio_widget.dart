import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/presentation/app_toast.dart';

class ReproductorAudioWidget extends StatefulWidget {
  final Duration duracion;
  final bool esMio;
  final String audioUrl;

  const ReproductorAudioWidget({
    super.key,
    required this.duracion,
    required this.esMio,
    required this.audioUrl,
  });

  @override
  State<ReproductorAudioWidget> createState() => _ReproductorAudioWidgetState();
}

class _ReproductorAudioWidgetState extends State<ReproductorAudioWidget> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration? _loadedDuration;
  String? _loadedUrl;
  bool _loading = false;
  bool _playing = false;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      if (mounted) setState(() => _loadedDuration = duration);
    });
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing =
            state.playing && state.processingState != ProcessingState.completed;
      });
    });
  }

  @override
  void didUpdateWidget(covariant ReproductorAudioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _player.stop();
      _position = Duration.zero;
      _loadedDuration = null;
      _loadedUrl = null;
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_playing) {
        await _player.pause();
        return;
      }
      setState(() => _loading = true);
      if (_loadedUrl != widget.audioUrl) {
        await _player.setUrl(widget.audioUrl);
        _loadedUrl = widget.audioUrl;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      unawaited(_playUntilComplete());
    } catch (_) {
      _showPlaybackError();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playUntilComplete() async {
    try {
      await _player.play();
    } catch (_) {
      _showPlaybackError();
    }
  }

  void _showPlaybackError() {
    if (mounted) {
      AppToast.error(context, 'No fue posible reproducir este audio.');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _loadedDuration ?? widget.duracion;
    final maximum = total.inMilliseconds > 0
        ? total.inMilliseconds.toDouble()
        : 1.0;
    final current = _position.inMilliseconds
        .clamp(0, maximum.toInt())
        .toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: _playing ? 'Pausar audio' : 'Reproducir audio',
          icon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 26,
                ),
          onPressed: _loading ? null : _togglePlayback,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: current,
              max: maximum,
              activeColor: widget.esMio ? AppColors.accent : Colors.tealAccent,
              inactiveColor: Colors.white24,
              onChanged: total.inMilliseconds == 0
                  ? null
                  : (value) =>
                        _player.seek(Duration(milliseconds: value.round())),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_format(_position)} / ${_format(total)}',
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
