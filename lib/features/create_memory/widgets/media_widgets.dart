// lib/features/create_memory/widgets/media_widgets.dart
import 'package:flutter/material.dart';
import '../../../features/create_memory/providers/memory_provider.dart';
import 'base64_media_display.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItemWithFile> mediaItems;
  final Function(int) onRemove;

  const MediaGrid({
    Key? key,
    required this.mediaItems,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return MediaItemCard(
          mediaItem: item,
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}

class MediaItemCard extends StatelessWidget {
  final MediaItemWithFile mediaItem;
  final VoidCallback onRemove;

  const MediaItemCard({
    Key? key,
    required this.mediaItem,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Media content
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildMediaPreview(),
        ),
        
        // Upload progress indicator
        if (mediaItem.uploadProgress > 0 && mediaItem.uploadProgress < 1.0)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: mediaItem.uploadProgress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(mediaItem.uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        
        // Type indicator
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(),
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTypeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    // If the media is uploaded (has a URL and is marked as uploaded)
    if (mediaItem.isUploaded && mediaItem.uploadedItem != null) {
      return Base64MediaPreview(
        mediaId: mediaItem.uploadedItem!.url,
        mediaType: mediaItem.type,
      );
    }
    
    // For files that haven't been uploaded yet, show local preview
    if (mediaItem.previewUrl == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    switch (mediaItem.type) {
      case 'image':
        // For images - display them from the object URL (local preview)
        return Image.network(
          mediaItem.previewUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );

      case 'video':
        // For videos - display thumbnail with video icon
        return Stack(
          children: [
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        );

      case 'audio':
        // For audio - display a waveform icon
        return Container(
          color: Colors.lightBlue[50],
          child: const Center(
            child: Icon(
              Icons.graphic_eq,
              color: Colors.blue,
              size: 40,
            ),
          ),
        );

      default:
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.help, color: Colors.grey),
          ),
        );
    }
  }

  IconData _getTypeIcon() {
    switch (mediaItem.type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.attachment;
    }
  }

  String _getTypeLabel() {
    switch (mediaItem.type) {
      case 'image':
        return 'Image';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      default:
        return 'File';
    }
  }

  Color _getTypeColor() {
    switch (mediaItem.type) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class MediaPreview extends StatelessWidget {
  final List<MediaItemWithFile> mediaItems;

  const MediaPreview({
    Key? key,
    required this.mediaItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No media selected'),
        ),
      );
    }

    // If there's only one media item, show it full width
    if (mediaItems.length == 1) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildSingleMediaPreview(mediaItems.first),
      );
    }
// If there are multiple media items, create a collage
    return SizedBox(
      height: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: mediaItems.length >= 4 ? 2 : 1,
          childAspectRatio: mediaItems.length >= 4 ? 1 : 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: mediaItems.length > 4 ? 4 : mediaItems.length,
        itemBuilder: (context, index) {
          final item = mediaItems[index];
          
          // If there are more than 4 items, show count on the last one
          if (index == 3 && mediaItems.length > 4) {
            return Stack(
              children: [
                // Base image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildSingleMediaPreview(item),
                ),
                // Overlay for +X more
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+${mediaItems.length - 3}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildSingleMediaPreview(item),
          );
        },
      ),
    );
  }

  Widget _buildSingleMediaPreview(MediaItemWithFile item) {
    // If the item is uploaded, show from Firestore
    if (item.isUploaded && item.uploadedItem != null) {
      return Base64MediaPreview(
        mediaId: item.uploadedItem!.url,
        mediaType: item.type,
      );
    }
    
    // Otherwise show local preview
    if (item.previewUrl == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    switch (item.type) {
      case 'image':
        // For images - display them directly
        return Image.network(
          item.previewUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
        );

      case 'video':
        // For videos - display thumbnail with video icon
        return Stack(
          children: [
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        );

      case 'audio':
        // For audio - display a waveform icon
        return Container(
          color: Colors.lightBlue[50],
          child: const Center(
            child: Icon(
              Icons.graphic_eq,
              color: Colors.blue,
              size: 40,
            ),
          ),
        );

      default:
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.help, color: Colors.grey),
          ),
        );
    }
  }
}





















