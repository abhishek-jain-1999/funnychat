import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_constants.dart';
import '../models/message.dart';
import 'api_service.dart';

class MediaServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;

  MediaServiceException(this.message, {this.statusCode, this.type});

  @override
  String toString() => 'MediaServiceException: $message (code: $statusCode, type: $type)';
}

class MediaService {
  final http.Client _client;

  MediaService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw MediaServiceException('No authentication token available', type: 'AUTH_ERROR');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Request presigned upload URL from chat backend
  Future<UploadUrlResponse> getUploadUrl({
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomMediaUploadUrl(roomId)}');
      
      final body = {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UploadUrlResponse.fromJson(data['data']);
        } else {
          throw MediaServiceException(
            data['message'] ?? 'Failed to get upload URL',
            statusCode: response.statusCode,
            type: 'API_ERROR',
          );
        }
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw MediaServiceException(
          error['message'] ?? 'Invalid request',
          statusCode: response.statusCode,
          type: 'VALIDATION_ERROR',
        );
      } else if (response.statusCode == 401) {
        throw MediaServiceException(
          'Authentication failed',
          statusCode: response.statusCode,
          type: 'AUTH_ERROR',
        );
      } else {
        throw MediaServiceException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          type: 'SERVER_ERROR',
        );
      }
    } on SocketException catch(e, st) {
      throw MediaServiceException('Network error', type: 'NETWORK_ERROR');
    } on MediaServiceException {
      rethrow;
    } catch (e) {
      throw MediaServiceException('Unexpected error: $e', type: 'UNKNOWN_ERROR');
    }
  }

  /// Upload file to MinIO using presigned URL
  Future<void> uploadToMinIO({
    required String uploadUrl,
    required XFile file,
    required String mimeType,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      final totalBytes = await file.length();
      final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
      request.headers['Content-Type'] = mimeType;
      request.headers['Content-Length'] = totalBytes.toString();

      // 1. Create a transforming stream for Progress
      final stream = file.openRead();
      int uploaded = 0;

      final Stream<List<int>> trackedStream = stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            uploaded += data.length;
            onProgress?.call(uploaded, totalBytes); // Update progress
            sink.add(data);
          },
          handleError: (error, stack, sink) => sink.addError(error, stack),
          handleDone: (sink) => sink.close(),
        ),
      );

      // // 2. Pipe the stream directly to the request sink
      // // 'addStream' waits until the stream is fully consumed and handles backpressure
      // await request.sink.addStream(trackedStream);
      //
      // // 3. Close the sink (signals EOF)
      // // await request.sink.close();
      //
      // // 4. Send request
      // final streamedResponse = await _client.send(request);


      final uploadFuture = () async {
        await request.sink.addStream(trackedStream);
        await request.sink.close();
      }();

      // 3. FUTURE 2: The Network Request (Read from Sink)
      // This starts listening to the sink immediately, unblocking the uploadFuture.

      // 4. Wait for both (optional, usually just wait for response)
      // Ideally, wait for the response. If upload fails, response will throw.
      final streamedResponse = await _client.send(request);

      // 5. Wait for the upload loop to finish cleanly (just to be safe/clean up)
      await uploadFuture;

      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode != 200) {
        throw MediaServiceException(
          'Failed to upload to MinIO: ${response.statusCode}',
          statusCode: response.statusCode,
          type: 'UPLOAD_ERROR',
        );
      }
    } on SocketException {
      throw MediaServiceException('Network error during upload', type: 'NETWORK_ERROR');
    } on MediaServiceException {
      rethrow;
    } catch (e) {
      throw MediaServiceException('Upload failed: $e', type: 'UPLOAD_ERROR');
    }
  }

  void dispose() {
    _client.close();
  }
}
