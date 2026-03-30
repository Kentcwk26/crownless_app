import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CarouselSection extends StatefulWidget {
  final List<String> imagePaths;
  const CarouselSection({super.key, required this.imagePaths});

  @override
  State<CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<CarouselSection> {
  final List<double> _aspectRatios = [];

  @override
  void initState() {
    super.initState();
    _loadAspectRatios();
  }

  Future<void> _loadAspectRatios() async {
    final List<double> ratios = [];

    for (final path in widget.imagePaths) {
      try {
        final completer = Completer<ui.Image>();

        ImageProvider imageProvider;

        if (path.startsWith('http')) {
          imageProvider = CachedNetworkImageProvider(path);
        } else {
          imageProvider = AssetImage(path);
        }

        imageProvider.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) => completer.complete(info.image)),
        );

        final img = await completer.future;
        final ratio = img.width / img.height;
        ratios.add(ratio);
      } catch (_) {
        ratios.add(1.0);
      }
    }

    if (mounted) {
      setState(() {
        _aspectRatios
          ..clear()
          ..addAll(ratios);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveHeight = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: effectiveHeight,
        width: double.infinity,
        child: CarouselSlider.builder(
          itemCount: widget.imagePaths.length,
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            height: effectiveHeight,
          ),
          itemBuilder: (context, index, realIndex) {
            final path = widget.imagePaths[index];
      
            Widget imageWidget;
      
            if (path.startsWith('http')) {
              imageWidget = CachedNetworkImage(
                imageUrl: path,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 60),
              );
            } else {
              imageWidget = Image.asset(
                path,
                fit: BoxFit.contain,
              );
            }
      
            return GestureDetector(
              onTap: () => _showZoomableGallery(context, widget.imagePaths, index),
              child: Center(child: imageWidget),
            );
          },
        ),
      ),
    );
  }

  void _showZoomableGallery(BuildContext context, List<String> imagePaths, int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Close zoom view',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: ZoomableImageGallery(
            imagePaths: imagePaths,
            initialIndex: initialIndex,
          ),
        );
      },
    );
  }
}

class ZoomableImageGallery extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ZoomableImageGallery({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<ZoomableImageGallery> createState() => _ZoomableImageGalleryState();
}

class _ZoomableImageGalleryState extends State<ZoomableImageGallery> with SingleTickerProviderStateMixin {
  late PageController _pageController;

  double _dragY = 0;
  double _scale = 1.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ImageProvider _getImageProvider(String path) {
    return path.startsWith('http')
        ? CachedNetworkImageProvider(path)
        : AssetImage(path);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragY += details.delta.dy;

    final dragPercent = (_dragY.abs() / 400).clamp(0.0, 1.0);

    setState(() {
      _scale = 1 - (dragPercent * 0.25);
      _opacity = 1 - dragPercent;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (_dragY.abs() > 150 || velocity.abs() > 800) {
      Navigator.of(context).pop();
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
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _opacity,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),

          Transform.translate(
            offset: Offset(0, _dragY),
            child: Transform.scale(
              scale: _scale,
              child: PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.imagePaths.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: _ZoomableImage(
                      imageProvider: _getImageProvider(widget.imagePaths[index]),
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                  );
                },
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _opacity,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
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
  final PhotoViewController _controller = PhotoViewController();
  final PhotoViewScaleStateController _scaleStateController = PhotoViewScaleStateController();

  TapDownDetails? _tapDetails;

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final scale = _controller.scale ?? 1.0;

    if (scale > 1.0) {
      _controller.scale = 1.0;
      _controller.position = Offset.zero;
    } else {
      final position = _tapDetails!.localPosition;

      final zoomScale = 2.5;

      final offset = Offset(
        -position.dx * (zoomScale - 1),
        -position.dy * (zoomScale - 1),
      );

      _controller.scale = zoomScale;
      _controller.position = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _tapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: PhotoView(
        imageProvider: widget.imageProvider,
        controller: _controller,
        scaleStateController: _scaleStateController,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }
}