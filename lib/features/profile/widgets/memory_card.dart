import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/memory_capsule.dart';
import '../../create_memory/widgets/base64_media_display.dart';
import '../../profile/screens/edit_memory_screen.dart';

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
    final theme = Theme.of(context);
    final hasMedia = memory.media.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMedia)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Base64Image(
                  mediaId: memory.media.first.url,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCapsuleIcon(),
                      color: _getCapsuleColor(theme),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCapsuleName(),
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMemoryScreen(memory: memory),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                if (memory.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(memory.message),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        memory.locationName,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${DateFormat.yMMMd().format(memory.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (memory.lastUpdatedAt != null)
                  Text(
                    'Updated ${DateFormat.yMMMd().format(memory.lastUpdatedAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCapsuleIcon() {
    switch (memory.capsuleType) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      case 'standard':
      default:
        return Icons.accessibility;
    }
  }

  Color _getCapsuleColor(ThemeData theme) {
    switch (memory.capsuleType) {
      case 'birthday':
        return const Color(0xFFFF6584);
      case 'anniversary':
        return const Color(0xFFF9A826);
      case 'travel':
        return const Color(0xFF43B5C3);
      case 'standard':
      default:
        return const Color(0xFF6C63FF);
    }
  }

  String _getCapsuleName() {
    switch (memory.capsuleType) {
      case 'birthday':
        return 'Birthday Memory';
      case 'anniversary':
        return 'Anniversary Memory';
      case 'travel':
        return 'Travel Memory';
      case 'standard':
      default:
        return 'Standard Memory';
    }
  }
} 