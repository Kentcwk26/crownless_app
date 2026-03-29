import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

enum MediaType { asset, network }
enum MediaKind { image, video }

class BlogItem {
  final String path;
  final MediaType type;
  final MediaKind kind;
  final String description;
  final String createdAt;

  BlogItem({
    required this.path,
    required this.type,
    required this.kind,
    required this.description,
    required this.createdAt
  });
}

final List<BlogItem> items = [
  BlogItem(
    path: "assets/videos/Video2.mp4",
    type: MediaType.asset,
    kind: MediaKind.video,
    description: "Dance Practice 🔥",
    createdAt: "17/01/2026"
  ),
  BlogItem(
    path: "assets/images/photo3.jpg",
    type: MediaType.asset,
    kind: MediaKind.image,
    description: "Yeay 🙌",
    createdAt: "17/01/2026"
  ),
  BlogItem(
    path: "assets/images/photo4.jpg",
    type: MediaType.asset,
    kind: MediaKind.image,
    description: "Stay Tuned 🫡",
    createdAt: "31/01/2026"
  ),
];

class MediaCard extends StatefulWidget {
  final String path;
  final MediaType type;
  final MediaKind kind;
  final String description;
  final String createdAt;
  final int index;

  const MediaCard({
    super.key,
    required this.path,
    required this.type,
    required this.kind,
    required this.description,
    required this.createdAt,
    required this.index,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.kind == MediaKind.video) {
      _controller = widget.type == MediaType.asset
          ? VideoPlayerController.asset(widget.path)
          : VideoPlayerController.networkUrl(Uri.parse(widget.path));

      _controller!.initialize().then((_) {
        setState(() {});
        _controller!.setLooping(true);
        _controller!.setVolume(0);
        _controller!.play();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildMedia() {
    if (widget.kind == MediaKind.image) {
      return widget.type == MediaType.asset
          ? Image.asset(widget.path, fit: BoxFit.cover)
          : Image.network(widget.path, fit: BoxFit.cover);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => FullscreenViewer(
              items: items,
              initialIndex: widget.index,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: "media_${widget.index}", 
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildMedia(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(widget.description),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text("Posted on: ${widget.createdAt}", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final String path;
  final String name;

  const VideoPreview({
    super.key,
    required this.path,
    required this.name,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ],
        ),
        Text(widget.name),
      ],
    );
  }
}

class VideoPreviewMini extends StatefulWidget {
  final String path;

  const VideoPreviewMini({super.key, required this.path});

  @override
  State<VideoPreviewMini> createState() => _VideoPreviewMiniState();
}

class _VideoPreviewMiniState extends State<VideoPreviewMini> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        IconButton(
          icon: Icon(
            controller.value.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle,
            size: 40,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            });
          },
        ),
      ],
    );
  }
}

class FullscreenViewer extends StatefulWidget {
  final List<BlogItem> items;
  final int initialIndex;

  const FullscreenViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<FullscreenViewer> {
  late PageController _controller;

  double _dragY = 0;
  double _scale = 1;
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragY += details.delta.dy;

    final percent = (_dragY.abs() / 400).clamp(0.0, 1.0);

    setState(() {
      _scale = 1 - percent * 0.25;
      _opacity = 1 - percent;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (_dragY.abs() > 150 || velocity.abs() > 800) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragY = 0;
        _scale = 1;
        _opacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _opacity,
              child: Container(color: Colors.black),
            ),

            Transform.translate(
              offset: Offset(0, _dragY),
              child: Transform.scale(
                scale: _scale,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Hero(
                              tag: "media_$index",
                              child: item.kind == MediaKind.image
                                  ? _ZoomableImage(
                                      imageProvider: item.type == MediaType.network
                                          ? NetworkImage(item.path)
                                          : AssetImage(item.path) as ImageProvider,
                                    )
                                  : _FullscreenVideo(path: item.path),
                            ),
                          ),
                        ),
                        
                        if (item.description.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  final String path;

  const _FullscreenVideo({required this.path});

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.asset(widget.path);

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final ImageProvider imageProvider;

  const _ZoomableImage({required this.imageProvider});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _tapDetails;

  void _handleDoubleTap() {
    final matrix = _controller.value;

    if (matrix != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      final position = _tapDetails!.localPosition;

      _controller.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _tapDetails = d,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 4,
        child: Image(
          image: widget.imageProvider,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class FourImageRow extends StatelessWidget {
  final List<String> images;
  final List<String?>? links;
  final double width;
  final double height;
  final double spacing;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const FourImageRow({
    super.key,
    required this.images,
    this.links,
    this.width = 60,
    this.height = 60,
    this.spacing = 12,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  })  : assert(images.length == 4, 'Exactly 4 images are required'),
        assert(
          links == null || links.length == 4,
          'Links must be null or match images length',
        );

  bool _isNetwork(String path) {
    return path.startsWith('http') || path.startsWith('https');
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(images.length, (index) {
        final image = images[index];
        final link = links != null ? links![index] : null;

        Widget imageWidget = ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            width: width,
            height: height,
            child: _isNetwork(image)
                ? Image.network(
                    image,
                    fit: fit,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image);
                    },
                  )
                : Image.asset(
                    image,
                    fit: fit,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image);
                    },
                  ),
          ),
        );

        if (link != null && link.isNotEmpty) {
          imageWidget = GestureDetector(
            onTap: () => _openLink(link),
            child: imageWidget,
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            right: index != images.length - 1 ? spacing : 0,
          ),
          child: imageWidget,
        );
      }),
    );
  }
}

class FileUploadCard extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool isVideo;

  const FileUploadCard({
    super.key,
    required this.file,
    required this.onPick,
    required this.onRemove,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.grey.shade300);

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: file == null
            ? _emptyState()
            : _previewState(context),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.cloud_upload_outlined, size: 40),
        SizedBox(height: 8),
        Text("Tap to upload"),
      ],
    );
  }

  Widget _previewState(BuildContext context) {
    final ext = file!.extension?.toLowerCase();
    final path = file!.path!;

    Widget preview;

    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(path), height: 120, fit: BoxFit.cover),
      );
    } else if (isVideo) {
      preview = VideoPreviewMini(path: path);
    } else {
      preview = Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Text(file!.name)),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(path),
          )
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                file!.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onPick,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}