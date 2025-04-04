// lib/features/profile/widgets/memory_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/memory_capsule.dart';
import '../../theme/theme_provider.dart';
import '../../../core/utils/date_formatter.dart';

class MemoryCard extends StatelessWidget {
  final MemoryCapsule memory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MemoryCard({
    Key? key,
    required this.memory,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with memory type and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getCapsuleColor(memory.capsuleType).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCapsuleIcon(memory.capsuleType),
                      color: _getCapsuleColor(memory.capsuleType),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCapsuleName(memory.capsuleType),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCapsuleColor(memory.capsuleType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Privacy indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: memory.privacy == MemoryPrivacy.public
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            memory.privacy.icon,
                            size: 14,
                            color: memory.privacy == MemoryPrivacy.public
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memory.privacy.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: memory.privacy == MemoryPrivacy.public
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: _getCapsuleColor(memory.capsuleType),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Memory content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        memory.locationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Created date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDate(memory.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message
                if (memory.message.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      memory.message,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Media preview
                if (memory.mediaItems.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: memory.mediaItems.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMediaIcon(memory.mediaItems[index].type),
                            color: isDarkMode ? Colors.white60 : Colors.grey[700],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to get color, icon, and name based on memory type
  Color _getCapsuleColor(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return const Color(0xFFFF6584);
      case 'anniversary':
        return const Color(0xFFF9A826);
      case 'travel':
        return const Color(0xFF43B5C3);
      default:
        return const Color(0xFF6C63FF); // standard
    }
  }

  IconData _getCapsuleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.accessibility;
    }
  }

  String _getCapsuleName(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return 'Birthday';
      case 'anniversary':
        return 'Anniversary';
      case 'travel':
        return 'Travel';
      default:
        return 'Standard';
    }
  }

  IconData _getMediaIcon(String type) {
    switch (type.toLowerCase()) {
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
}