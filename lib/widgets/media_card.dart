import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  IconData get _icon {
    switch (item.kind) {
      case MediaKind.videoFile:
        return Icons.movie_outlined;
      case MediaKind.blurayFolder:
        return Icons.album;
      case MediaKind.dvdFolder:
        return Icons.album_outlined;
      case MediaKind.iso:
        return Icons.disc_full;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_icon, size: 48, color: AppTheme.accent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.kind.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onRemove,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
