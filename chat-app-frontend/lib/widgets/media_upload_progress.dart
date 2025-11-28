import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../notifiers/media_upload_notifier.dart';

class MediaUploadProgress extends StatelessWidget {
  final String clientId;
  final MediaUploadNotifier mediaUploadNotifier;

  const MediaUploadProgress({
    super.key, 
    required this.clientId,
    required this.mediaUploadNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final uploadState = mediaUploadNotifier.getUpload(clientId);

    if (uploadState == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  uploadState.fileName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uploadState.status == MediaUploadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  color: AppTheme.accentColor,
                  onPressed: () {
                    mediaUploadNotifier.retryUpload(clientId);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: AppTheme.textSecondary,
                onPressed: () {
                  mediaUploadNotifier.cancelUpload(clientId);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (uploadState.status == MediaUploadStatus.uploading)
            LinearProgressIndicator(
              value: uploadState.progress,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            )
          else if (uploadState.status == MediaUploadStatus.pending)
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            )
          else if (uploadState.status == MediaUploadStatus.confirming)
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            )
          else if (uploadState.status == MediaUploadStatus.completed)
            const Text(
              'Upload completed',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          else if (uploadState.status == MediaUploadStatus.failed)
            Text(
              uploadState.error ?? 'Upload failed',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          if (uploadState.status != MediaUploadStatus.completed && 
              uploadState.status != MediaUploadStatus.failed)
            const SizedBox(height: 4),
          if (uploadState.status != MediaUploadStatus.completed && 
              uploadState.status != MediaUploadStatus.failed)
            Text(
              '${(uploadState.progress * 100).round()}% • ${(uploadState.sizeBytes / 1024).round()} KB',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}