import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_item.dart';

/// Widget that displays either an image or video ad item
class AdDisplayWidget extends StatefulWidget {
  final MediaItem mediaItem;
  final VoidCallback onComplete;
  final bool isPipMode;

  const AdDisplayWidget({
    super.key,
    required this.mediaItem,
    required this.onComplete,
    this.isPipMode = false,
  });

  @override
  State<AdDisplayWidget> createState() => _AdDisplayWidgetState();
}

class _AdDisplayWidgetState extends State<AdDisplayWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItem.isVideo) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant AdDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItem.id != widget.mediaItem.id) {
      _disposeVideo();
      if (widget.mediaItem.isVideo) {
        _initializeVideo();
      }
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaItem.url),
    );

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _videoController!.play();
        _videoController!.addListener(_onVideoProgress);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() => _hasError = true);
        // Skip to next on error after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  void _onVideoProgress() {
    if (_videoController == null) return;
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    if (position >= duration && duration > Duration.zero) {
      widget.onComplete();
    }
  }

  void _disposeVideo() {
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (widget.mediaItem.isVideo) {
      return _buildVideoPlayer();
    } else {
      return _buildImageDisplay();
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        if (!widget.isPipMode)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: false,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    return CachedNetworkImage(
      imageUrl: widget.mediaItem.url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Failed to load media',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
