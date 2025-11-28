import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message.dart';
import '../services/media_service.dart';

enum MediaUploadStatus {
  pending,
  uploading,
  confirming,
  completed,
  failed,
}

class MediaUploadState {
  final String clientId; // Temporary ID for tracking
  final String roomId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final XFile? file;
  final int? width;
  final int? height;
  final MediaUploadStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;
  final UploadUrlResponse? uploadResponse;
  final MediaAttachment? mediaAttachment;

  MediaUploadState({
    required this.clientId,
    required this.roomId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.file,
    this.width,
    this.height,
    this.status = MediaUploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.uploadResponse,
    this.mediaAttachment,
  });

  MediaUploadState copyWith({
    MediaUploadStatus? status,
    double? progress,
    String? error,
    UploadUrlResponse? uploadResponse,
    MediaAttachment? mediaAttachment,
    XFile? file,
    int? width,
    int? height,
  }) {
    return MediaUploadState(
      clientId: clientId,
      roomId: roomId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      file: file ?? this.file,
      width: width ?? this.width,
      height: height ?? this.height,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
      uploadResponse: uploadResponse ?? this.uploadResponse,
      mediaAttachment: mediaAttachment ?? this.mediaAttachment,
    );
  }
}

class MediaUploadNotifier extends ChangeNotifier {
  final MediaService _mediaService;
  final Map<String, MediaUploadState> _uploads = {};

  MediaUploadNotifier(this._mediaService);

  Map<String, MediaUploadState> get uploads => Map.unmodifiable(_uploads);

  MediaUploadState? getUpload(String clientId) => _uploads[clientId];

  /// Start media upload process
  Future<MediaAttachment?> uploadMedia({
    required String clientId,
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required XFile file,
    int? width,
    int? height,
  }) async {
    // Initialize upload state
    _uploads[clientId] = MediaUploadState(
      clientId: clientId,
      roomId: roomId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      file: file,
      width: width,
      height: height,
      status: MediaUploadStatus.pending,
    );
    notifyListeners();

    try {
      // Step 1: Get upload URL
      final uploadResponse = await _mediaService.getUploadUrl(
        roomId: roomId,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
      );

      _uploads[clientId] = _uploads[clientId]!.copyWith(
        status: MediaUploadStatus.uploading,
        uploadResponse: uploadResponse,
      );
      notifyListeners();

      // Step 2: Upload to MinIO
      await _mediaService.uploadToMinIO(
        uploadUrl: uploadResponse.uploadUrl,
        file: file,
        mimeType: mimeType,
        onProgress: (sent, total) {
          final progress = sent / total;
          _uploads[clientId] = _uploads[clientId]!.copyWith(
            progress: progress,
          );
          notifyListeners();
        },
      );


      // In the new architecture, confirmation happens automatically on the backend
      // We can create a MediaAttachment from the upload response
      final mediaAttachment = MediaAttachment(
        mediaId: uploadResponse.mediaId,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
      );

      _uploads[clientId] = _uploads[clientId]!.copyWith(
        status: MediaUploadStatus.completed,
        progress: 1.0,
        mediaAttachment: mediaAttachment,
      );
      notifyListeners();


      return mediaAttachment;
    } on MediaServiceException catch (e,st) {
      _uploads[clientId] = _uploads[clientId]!.copyWith(
        status: MediaUploadStatus.failed,
        error: e.message,
      );
      notifyListeners();
      rethrow;
    } catch (e,st) {
      _uploads[clientId] = _uploads[clientId]!.copyWith(
        status: MediaUploadStatus.failed,
        error: e.toString(),
      );
      notifyListeners();
      rethrow;
    } finally {
      clearCompleted();
    }
  }

  /// Retry failed upload
  Future<MediaAttachment?> retryUpload(String clientId) async {
    final upload = _uploads[clientId];
    if (upload == null || upload.file == null) {
      throw Exception('Upload state not found or file missing');
    }

    // In the new architecture, we don't need to confirm uploads
    // Just restart the entire process if it failed
    return uploadMedia(
      clientId: clientId,
      roomId: upload.roomId,
      fileName: upload.fileName,
      mimeType: upload.mimeType,
      sizeBytes: upload.sizeBytes,
      file: upload.file!,
      width: upload.width,
      height: upload.height,
    );
  }

  /// Cancel and remove upload
  void cancelUpload(String clientId) {
    _uploads.remove(clientId);
    notifyListeners();
  }

  /// Clear completed uploads
  void clearCompleted() {
    _uploads.removeWhere((key, value) => value.status == MediaUploadStatus.completed);
    notifyListeners();
  }

  @override
  void dispose() {
    _uploads.clear();
    super.dispose();
  }
}
