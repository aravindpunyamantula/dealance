import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import '../../utils/app_palette.dart';

class FeedMediaGallery extends StatelessWidget {
  final List<String> mediaUrls;

  const FeedMediaGallery({super.key, required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: mediaUrls.length,
          itemBuilder: (context, index) {
            final url = mediaUrls[index];
            final ext = url.split('?').first.split('.').last.toLowerCase();
            
            Widget child;
            if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
              child = _FeedVideoPlayer(url: url);
            } else if (['pdf', 'doc', 'docx'].contains(ext)) {
              child = _DocumentTile(url: url, ext: ext);
            } else {
              // Assume image
              child = CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppPalette.surfaceElevated,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppPalette.surfaceElevated,
                  child: const Center(child: Icon(Iconsax.image, color: AppPalette.textSecondary)),
                ),
              );
            }

            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.black.withValues(alpha: 0.02),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _FeedVideoPlayer extends StatefulWidget {
  final String url;
  const _FeedVideoPlayer({required this.url});

  @override
  State<_FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<_FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() { _isInitialized = true; });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayer(_controller),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying ? Iconsax.pause : Iconsax.play,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String url;
  final String ext;
  const _DocumentTile({required this.url, required this.ext});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        color: AppPalette.surfaceElevated,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ext == 'pdf' ? Iconsax.document : Iconsax.document_text, size: 48, color: AppPalette.primaryAccent),
            const SizedBox(height: 12),
            Text('Document (${ext.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppPalette.textPrimary)),
            const SizedBox(height: 4),
            const Text('Tap to open', style: TextStyle(fontSize: 12, color: AppPalette.textSecondary)),
          ],
        ),
      ),
    );
  }
}
