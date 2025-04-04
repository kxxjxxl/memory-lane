// lib/features/create_memory/widgets/base64_media_display.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Base64Image extends StatefulWidget {
  final String mediaId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const Base64Image({
    Key? key,
    required this.mediaId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Base64ImageState createState() => Base64ImageState();
}

class Base64ImageState extends State<Base64Image> {
  String? _base64Data;
  String? _contentType;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void didUpdateWidget(Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _loadImageData();
    }
  }

  Future<void> _loadImageData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final mediaDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('media')
          .doc(widget.mediaId)
          .get();

      if (!mediaDoc.exists) {
        throw Exception('Media not found');
      }

      final data = mediaDoc.data();

      if (data == null ||
          !data.containsKey('data') ||
          !data.containsKey('contentType')) {
        throw Exception('Invalid media data');
      }

      if (mounted) {
        setState(() {
          _base64Data = data['data'] as String;
          _contentType = data['contentType'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _base64Data == null) {
      return widget.errorWidget ??
          Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: 40,
            ),
          );
    }

    return Image.memory(
      Uri.parse('data:$_contentType;base64,$_base64Data')
          .data!
          .contentAsBytes(),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: 40,
              ),
            );
      },
    );
  }
}

class Base64MediaPreview extends StatelessWidget {
  final String mediaId;
  final String mediaType;
  final bool showControls;

  const Base64MediaPreview({
    Key? key,
    required this.mediaId,
    required this.mediaType,
    this.showControls = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (mediaType) {
      case 'image':
        return Stack(
          alignment: Alignment.center,
          children: [
            Base64Image(
              mediaId: mediaId,
              fit: BoxFit.cover,
            ),
            if (showControls)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        );

      case 'video':
        // For videos - simple preview with icon
        return Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
              if (showControls)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        );

      case 'audio':
        // For audio - waveform icon on colored background
        return Container(
          color: Colors.blue.withOpacity(0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.audiotrack,
                color: Colors.blue,
                size: 40,
              ),
              if (showControls)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        );

      default:
        return Container(
          color: Colors.grey.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.insert_drive_file,
              color: Colors.grey,
              size: 40,
            ),
          ),
        );
    }
  }
}
