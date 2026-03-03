import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';

class LuxuryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const LuxuryVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<LuxuryVideoPlayer> createState() => _LuxuryVideoPlayerState();
}

class _LuxuryVideoPlayerState extends State<LuxuryVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  bool _isPlaying = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0);
        }
      });
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final playing = _controller.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      _controller.play();
      _controller.setVolume(1.0);
      _resetHideTimer();
    }
  }

  void _onTapOverlay() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _isPlaying) {
      _resetHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: kCreamBg,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: GestureDetector(
            onTap: _onTapOverlay,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail or video
                if (_initialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else if (widget.thumbnailUrl != null)
                  Image.network(
                    widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: kCreamBg),
                  )
                else
                  Container(color: kCreamBg),

                // Loading indicator
                if (!_initialized)
                  const Center(
                    child: CircularProgressIndicator(
                      color: kGoldPrimary,
                      strokeWidth: 2,
                    ),
                  ),

                // Controls overlay
                if (_initialized)
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Center play/pause button
                          Center(
                            child: GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.85),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 32,
                                  color: kGoldPrimary,
                                ),
                              ),
                            ),
                          ),

                          // Bottom progress bar
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: _LuxuryProgressBar(
                              controller: _controller,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LuxuryProgressBar extends StatefulWidget {
  final VideoPlayerController controller;

  const _LuxuryProgressBar({required this.controller});

  @override
  State<_LuxuryProgressBar> createState() => _LuxuryProgressBarState();
}

class _LuxuryProgressBarState extends State<_LuxuryProgressBar> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateProgress);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateProgress);
    super.dispose();
  }

  void _updateProgress() {
    if (!mounted) return;
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    if (duration.inMilliseconds > 0) {
      setState(() {
        _progress = position.inMilliseconds / duration.inMilliseconds;
      });
    }
  }

  void _seekTo(double dx, double maxWidth) {
    final fraction = (dx / maxWidth).clamp(0.0, 1.0);
    final duration = widget.controller.value.duration;
    widget.controller.seekTo(Duration(
      milliseconds: (fraction * duration.inMilliseconds).round(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) =>
              _seekTo(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _seekTo(details.localPosition.dx, constraints.maxWidth),
          child: Container(
            height: 20,
            alignment: Alignment.center,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: kDivider.withOpacity(0.6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: kGoldPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
