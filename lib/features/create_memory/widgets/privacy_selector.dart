// lib/features/create_memory/widgets/privacy_selector.dart
import 'package:flutter/material.dart';
import '../../../models/memory_capsule.dart';

class PrivacySelectorWidget extends StatelessWidget {
  final MemoryPrivacy selectedPrivacy;
  final Function(MemoryPrivacy) onPrivacyChanged;
  final bool isDarkMode;

  const PrivacySelectorWidget({
    Key? key,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPrivacyOption(
                context: context,
                privacy: MemoryPrivacy.private,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPrivacyOption(
                context: context,
                privacy: MemoryPrivacy.public,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyOption({
    required BuildContext context,
    required MemoryPrivacy privacy,
  }) {
    final isSelected = selectedPrivacy == privacy;
    
    return GestureDetector(
      onTap: () => onPrivacyChanged(privacy),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              privacy.icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isDarkMode
                      ? Colors.white70
                      : Colors.grey[700],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              privacy.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDarkMode
                        ? Colors.white
                        : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              privacy.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}