import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import 'dart:ui';

class HeroVideoBackground extends StatefulWidget {
  final String? videoUrl;
  const HeroVideoBackground({super.key, this.videoUrl});

  @override
  State<HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<HeroVideoBackground> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.videoUrl ?? '${ApiService.baseUrl}/videos/dresses_video.mp4';
    debugPrint('Hero video URL: $videoUrl');

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();

      if (mounted) {
        setState(() => _initialized = true);
        debugPrint('Hero video initialized: ${controller.value.size}');
      }
    } catch (e) {
      debugPrint('Hero video error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_initialized || _controller == null) {
      return _buildContainedImage('assets/images/hero1.png', isAsset: true);
    }

    final controller = _controller!;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContainedImage(String src, {bool isAsset = false}) {
    final image = isAsset
        ? Image.asset(src, fit: BoxFit.cover)
        : Image.network(src, fit: BoxFit.cover);

    final containedImage = isAsset
        ? Image.asset(src, fit: BoxFit.contain)
        : Image.network(src, fit: BoxFit.contain);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
              child: SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: image)),
            ),
          ),
        ),
        Center(child: containedImage),
      ],
    );
  }
}
