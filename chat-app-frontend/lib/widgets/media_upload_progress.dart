import 'package:flutter/material.dart';
import '../config/app_theme.dart';
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (uploadState == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.backgroundBorder),
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
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uploadState.status == MediaUploadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  color: primaryColor,
                  onPressed: () {
                    mediaUploadNotifier.retryUpload(clientId);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.textSecondary,
                onPressed: () {
                  mediaUploadNotifier.cancelUpload(clientId);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (uploadState.status == MediaUploadStatus.uploading)
            LinearProgressIndicator(
              value: uploadState.progress,
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            )
          else if (uploadState.status == MediaUploadStatus.pending)
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            )
          else if (uploadState.status == MediaUploadStatus.confirming)
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            )
          else if (uploadState.status == MediaUploadStatus.completed)
            const Text(
              'Upload completed',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          else if (uploadState.status == MediaUploadStatus.failed)
            Text(
              uploadState.error ?? 'Upload failed',
              style: const TextStyle(
                color: Color(0xFFE74C3C),
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
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}