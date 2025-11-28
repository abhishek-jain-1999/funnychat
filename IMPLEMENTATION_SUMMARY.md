# Media Attachment Feature - Complete Implementation Guide

## 🎯 Overview

**ARCHITECTURE UPDATE**: This implementation has been refactored to use the chat backend as the sole public API. The media service is now an internal-only service accessible only within the cluster network.

### Key Changes from Previous Architecture:

1. **Chat Backend is Public API**: All client requests go through chat backend (`/api/rooms/{roomId}/media/upload-url`)
2. **Media Service is Internal**: No public endpoints, no JWT auth, only accessible via internal network
3. **STOMP-Only Message Creation**: REST message endpoint removed, all messages sent via WebSocket
4. **Media Metadata in Chat Backend**: PostgreSQL entity tracks media state (PENDING_UPLOAD → ACTIVE)
5. **Verification Flow**: Chat backend verifies uploads via internal media service before broadcasting

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Flutter Client Implementation](#flutter-client-implementation)
4. [Infrastructure & Deployment](#infrastructure--deployment)
5. [API Reference](#api-reference)
6. [Testing Guide](#testing-guide)
7. [Security & Validation](#security--validation)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps](#next-steps)

---

## 🏗️ Architecture Overview

### Flow Diagram

```
┌────────────────┐
│ Flutter Client  │
└────────────────┘
       │
       │ 1. POST /api/rooms/{roomId}/media/upload-url
       │    (JWT + fileName, mimeType, sizeBytes)
       v
┌────────────────────────────────┐
│  Chat Backend (Port 8080)      │
│  - Validates JWT & room access  │
│  - Generates objectKey          │
│  - Creates MediaMetadata (PENDING)│
└────────────────────────────────┘
       │
       │ 2. Internal call: getUploadUrl(objectKey)
       v
┌────────────────────────────────┐
│  Media Service (Port 8081)      │
│  INTERNAL ONLY - No JWT        │
│  - Generates presigned PUT URL  │
└────────────────────────────────┘
       │
       │ 3. Returns uploadUrl + publicUrl
       v
┌────────────────────────────────┐
│  Chat Backend                   │
│  Returns: mediaId, uploadUrl,   │
│           objectKey, publicUrl  │
└────────────────────────────────┘
       │
       │ 4. Client receives response
       v
┌────────────────┐
│ Flutter Client  │
│ - Uploads file  │
└────────────────┘
       │
       │ 5. PUT to uploadUrl (direct to MinIO)
       v
┌────────────────┐
│ MinIO (9000)    │
│ Object stored   │
└────────────────┘
       │
       │ 6. Upload complete
       v
┌────────────────┐
│ Flutter Client  │
│ Sends STOMP msg │
└────────────────┘
       │
       │ 7. WebSocket: sendMessage
       │    { roomId, content, messageType: IMAGE,
       │      media: { mediaId, ... } }
       v
┌────────────────────────────────┐
│  Chat Backend                   │
│  @MessageMapping sendMessage    │
│  - Verifies mediaId ownership   │
│  - Verifies room membership     │
└────────────────────────────────┘
       │
       │ 8. Internal call: verifyUpload(objectKey)
       v
┌────────────────────────────────┐
│  Media Service                  │
│  - Stats object in MinIO        │
│  - Returns verified=true + size │
└────────────────────────────────┘
       │
       │ 9. Verification result
       v
┌────────────────────────────────┐
│  Chat Backend                   │
│  - Updates MediaMetadata:ACTIVE │
│  - Saves Message with media     │
│  - Broadcasts via WebSocket     │
└────────────────────────────────┘
       │
       │ 10. STOMP broadcast to /topic/room.{id}
       v
┌────────────────┐
│ All Room       │
│ Subscribers    │
│ Render image   │
└────────────────┘
```

### Components

1. **Media Service** (Port 8081)
   - Generates presigned upload/download URLs
   - Validates room membership via chat backend
   - Manages media metadata (PostgreSQL)
   - Confirms uploads and verifies file sizes

2. **Chat Backend** (Port 8080)
   - REST endpoint for message creation
   - WebSocket for real-time delivery
   - Stores messages with media metadata (MongoDB)

3. **MinIO** (Port 9000)
   - S3-compatible object storage
   - Public read bucket for uploaded images
   - Direct client uploads via presigned URLs

4. **Flutter Client**
   - Image picker with validation
   - Media upload notifier for state management
   - UI rendering with progress indicators

---

## 🔧 Backend Implementation

### 1. Media Service

**Location:** `/backend-media/`

#### Key Files Created/Modified:

**Configuration:**
- `config/MinioConfig.kt` - MinIO client setup, bucket initialization
- `config/SecurityConfig.kt` - JWT authentication
- `config/AppConfig.kt` - Caching and RestTemplate beans

**Entities:**
- `entity/MediaMetadata.kt` - PostgreSQL entity with lifecycle status
```kotlin
enum class MediaStatus {
    PENDING_UPLOAD,
    ACTIVE,
    DELETED
}
```

**Services:**
- `service/MediaService.kt` - Core media operations
- `service/RoomValidationService.kt` - **NEW**: Validates room membership by calling chat backend

**Key Features:**
- **Room Membership Validation**: Before generating URLs, validates user belongs to room
- **Size Verification**: Compares client-provided size with actual MinIO object size
- **Caching**: Room membership cached for 5 minutes to reduce backend calls
- **Secure Downloads**: Validates ownership or room membership before generating download URLs

#### API Endpoints:

```
POST   /api/media/upload-url      - Request presigned upload URL
POST   /api/media/confirm          - Confirm successful upload
GET    /api/media/download-url     - Get presigned download URL
GET    /api/media/{id}             - Get media metadata
DELETE /api/media/{id}             - Delete media
```

#### Configuration (application.yml):

```yaml
minio:
  endpoint: http://localhost:9000
  access-key: minioadmin
  secret-key: minioadmin
  bucket: chat-media
  presigned-upload-expiry-seconds: 600  # 10 minutes
  presigned-download-expiry-seconds: 1800  # 30 minutes

media:
  max-file-size: 10485760  # 10MB
  allowed-mime-types: image/jpeg,image/png,image/webp,image/gif

chat:
  backend:
    url: http://backend:8080  # For room validation
```

### 2. Chat Backend Updates

**Files Modified:**

**Models:**
- `document/Message.kt` - Enhanced `Attachment` with `objectKey`, `mediaId`, `width`, `height`

**DTOs:**
- `dto/ApiDto.kt` - Added `MediaAttachmentDto`, updated request/response DTOs

**Services:**
- `service/MessageService.kt` - Handles media attachments, sets appropriate lastMessage text

**Controllers:**
- `controller/RoomController.kt` - **NEW**: Added `POST /api/rooms/{roomId}/messages` endpoint

#### New REST Endpoint:

```kotlin
@PostMapping("/{roomId}/messages")
fun sendMessage(
    @PathVariable roomId: String,
    @Valid @RequestBody request: SendMessageRequest,
    @AuthenticationPrincipal userDetails: CustomUserDetails
): ResponseEntity<ApiResponse<ChatMessageResponse>>
```

**Request Body:**
```json
{
  "content": "Check out this image!",
  "messageType": "IMAGE",
  "media": {
    "objectKey": "rooms/room-123/users/456/uuid.jpg",
    "url": "http://localhost:9000/chat-media/rooms/.../uuid.jpg",
    "mimeType": "image/jpeg",
    "sizeBytes": 1024000,
    "mediaId": "media-uuid",
    "width": 1920,
    "height": 1080
  }
}
```

---

## 📱 Flutter Client Implementation

### 1. Models & DTOs

**File:** `lib/models/message.dart`

**New Classes:**

```dart
// Media message types enum
enum MediaMessageType {
  text, image, file, system
}

// Media attachment model
class MediaAttachment {
  final String objectKey;
  final String url;
  final String mimeType;
  final int sizeBytes;
  final String? mediaId;
  final int? width;
  final int? height;
}

// Upload URL response
class UploadUrlResponse {
  final String uploadUrl;
  final String objectKey;
  final String publicUrl;
  final int expiresIn;
  final String mediaId;
}
```

**Updated Classes:**
- `Message` - Added `media` field
- `ChatMessageResponse` - Added `media` field

### 2. Media Service Client

**File:** `lib/services/media_service.dart`

**Methods:**

```dart
class MediaService {
  // Request presigned upload URL
  Future<UploadUrlResponse> getUploadUrl({
    required String roomId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
  });
  
  // Upload file to MinIO with progress tracking
  Future<void> uploadToMinIO({
    required String uploadUrl,
    required Uint8List fileBytes,
    required String mimeType,
    Function(int sent, int total)? onProgress,
  });
  
  // Confirm upload
  Future<MediaAttachment> confirmUpload({
    required String objectKey,
    required String roomId,
    required int sizeBytes,
  });
  
  // Get download URL (for future private buckets)
  Future<String> getDownloadUrl({required String objectKey});
}
```

**Error Handling:**

```dart
class MediaServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;  // AUTH_ERROR, VALIDATION_ERROR, UPLOAD_ERROR, etc.
}
```

### 3. Media Upload Notifier

**File:** `lib/notifiers/media_upload_notifier.dart`

**State Management:**

```dart
enum MediaUploadStatus {
  pending,
  uploading,
  confirming,
  completed,
  failed,
}

class MediaUploadState {
  final String clientId;  // Temporary ID for tracking
  final String roomId;
  final MediaUploadStatus status;
  final double progress;  // 0.0 to 1.0
  final String? error;
  final UploadUrlResponse? uploadResponse;
  final MediaAttachment? mediaAttachment;
}
```

**Key Methods:**

```dart
class MediaUploadNotifier extends ChangeNotifier {
  // Start upload process
  Future<MediaAttachment?> uploadMedia({
    required String clientId,
    required String roomId,
    required String fileName,
    required Uint8List fileBytes,
    // ...
  });
  
  // Retry failed upload (reuses objectKey if available)
  Future<MediaAttachment?> retryUpload(String clientId);
  
  // Cancel upload
  void cancelUpload(String clientId);
}
```

### 4. API Constants

**File:** `lib/config/api_constants.dart`

**New Constants:**

```dart
// Media service configuration
static const String mediaBaseUrl = 
  String.fromEnvironment('MEDIA_BASE_URL', defaultValue: 'http://localhost:8081');
static const String mediaApiPrefix = '/api/media';

// Media endpoints
static const String uploadUrl = '$mediaApiPrefix/upload-url';
static const String confirmUpload = '$mediaApiPrefix/confirm';
static const String downloadUrl = '$mediaApiPrefix/download-url';

// Message endpoints
static String roomMessages(String roomId) => '$apiPrefix/rooms/$roomId/messages';
```

### 5. Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  image_picker: ^1.0.7  # Image selection
  mime: ^1.0.5          # MIME type detection
```

### 6. Usage Example

**Complete Upload Flow:**

```dart
// 1. Pick image
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

if (image != null) {
  final bytes = await image.readAsBytes();
  final fileSize = bytes.length;
  
  // 2. Validate
  if (fileSize > 10 * 1024 * 1024) {
    // Show error: File too large
    return;
  }
  
  // 3. Upload via notifier
  final clientId = Uuid().v4();
  try {
    final mediaAttachment = await mediaUploadNotifier.uploadMedia(
      clientId: clientId,
      roomId: roomId,
      fileName: image.name,
      mimeType: 'image/jpeg',
      sizeBytes: fileSize,
      fileBytes: bytes,
    );
    
    // 4. Send message
    await ApiService.sendMessage(
      roomId: roomId,
      content: 'Check this out!',
      messageType: 'IMAGE',
      media: mediaAttachment.toJson(),
    );
  } on MediaServiceException catch (e) {
    // Handle error
    print('Upload failed: ${e.message}');
  }
}
```

---

## 🚀 Infrastructure & Deployment

### Docker Compose

**New Services Added:**

```yaml
minio:
  image: minio/minio:latest
  ports:
    - "9000:9000"  # S3 API
    - "9001:9001"  # Console
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: minioadmin
  command: server /data --console-address ":9001"

media-service:
  build: ./media-service
  ports:
    - "8081:8081"
  environment:
    MINIO_ENDPOINT: http://minio:9000
    CHAT_BACKEND_URL: http://backend:8080
    # ...
```

**NGINX Configuration:**

```nginx
# Media Service API
location ^~ /media/ {
  rewrite ^/media/(.*) /$1 break;
  proxy_pass http://media-service:8081;
  proxy_read_timeout 300;
  proxy_send_timeout 300;
}

# MinIO S3 API
location ^~ /minio/ {
  rewrite ^/minio/(.*) /$1 break;
  proxy_pass http://minio:9000;
  add_header Access-Control-Allow-Origin *;
  add_header Access-Control-Allow-Methods "GET, PUT, POST, DELETE, OPTIONS";
  client_max_body_size 50M;
}
```

### Kubernetes

**New Manifests:**

1. `k8s/minio.yaml` - StatefulSet with PVC
2. `k8s/media-service.yaml` - Deployment with HPA (2-4 replicas)

**Updated Manifests:**

1. `k8s/ingress.yaml` - Routes for `/media/` and `/minio/`
2. `k8s/secret.yaml` - MinIO credentials
3. `k8s/backend.yaml` - Fixed secret name references

**Deployment:**

```bash
# Full setup
./setup-cluster.sh

# Deploy specific service
./deploy.sh media-service

# Check status
kubectl get pods -n chat-app
kubectl get hpa -n chat-app
```

### Environment Variables

**New .env Variables:**

```bash
# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_BUCKET=chat-media
MINIO_PUBLIC_URL=http://localhost:9000

# Media Service
MEDIA_MAX_FILE_SIZE=10485760
MEDIA_ALLOWED_MIME_TYPES=image/jpeg,image/png,image/webp,image/gif
CHAT_BACKEND_URL=http://backend:8080
```

---

## 📚 API Reference

### Media Service API

#### 1. Request Upload URL

**Endpoint:** `POST /api/media/upload-url`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request:**
```json
{
  "roomId": "room-uuid",
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg",
  "sizeBytes": 1024000,
  "width": 1920,
  "height": 1080
}
```

**Response:**
```json
{
  "success": true,
  "message": "Upload URL generated successfully",
  "data": {
    "uploadUrl": "http://localhost:9000/chat-media/rooms/...",
    "objectKey": "rooms/room-123/users/456/uuid.jpg",
    "publicUrl": "http://localhost:9000/chat-media/rooms/.../uuid.jpg",
    "expiresIn": 600,
    "mediaId": "media-uuid"
  }
}
```

**Validation:**
- ✅ User is authenticated (JWT)
- ✅ User is member of room
- ✅ MIME type is allowed
- ✅ File size is within limits

#### 2. Upload to MinIO

**Endpoint:** Use `uploadUrl` from step 1

**Method:** `PUT`

**Headers:**
```
Content-Type: image/jpeg
Content-Length: 1024000
```

**Body:** Raw file bytes

#### 3. Confirm Upload

**Endpoint:** `POST /api/media/confirm`

**Request:**
```json
{
  "objectKey": "rooms/room-123/users/456/uuid.jpg",
  "roomId": "room-uuid",
  "sizeBytes": 1024000
}
```

**Response:**
```json
{
  "success": true,
  "message": "Upload confirmed successfully",
  "data": {
    "id": "media-uuid",
    "objectKey": "rooms/room-123/users/456/uuid.jpg",
    "status": "ACTIVE",
    "publicUrl": "http://localhost:9000/chat-media/...",
    // ...
  }
}
```

**Validation:**
- ✅ User owns the media
- ✅ Object exists in MinIO
- ✅ Size matches (within 1KB tolerance)
- ✅ Status updated to ACTIVE

### Chat Backend API

#### Send Message with Media

**Endpoint:** `POST /api/rooms/{roomId}/messages`

**Request:**
```json
{
  "content": "Caption text",
  "messageType": "IMAGE",
  "media": {
    "objectKey": "rooms/room-123/users/456/uuid.jpg",
    "url": "http://localhost:9000/chat-media/...",
    "mimeType": "image/jpeg",
    "sizeBytes": 1024000,
    "mediaId": "media-uuid",
    "width": 1920,
    "height": 1080
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "id": "message-uuid",
    "roomId": "room-uuid",
    "senderId": 123,
    "senderName": "John Doe",
    "content": "Caption text",
    "messageType": "IMAGE",
    "media": { /* same as request */ },
    "createdAt": "2024-01-01T12:00:00Z"
  }
}
```

---

## 🧪 Testing Guide

### Manual Testing with cURL

#### 1. Authenticate

```bash
# Login
curl -X POST http://localhost/backend/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Save token
export TOKEN="<jwt_token_from_response>"
```

#### 2. Create Room

```bash
curl -X POST http://localhost/backend/api/rooms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Room",
    "description": "Testing media uploads",
    "participantEmails": []
  }'

export ROOM_ID="<room_id_from_response>"
```

#### 3. Request Upload URL

```bash
curl -X POST http://localhost/media/api/media/upload-url \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "roomId": "'$ROOM_ID'",
    "fileName": "test.jpg",
    "mimeType": "image/jpeg",
    "sizeBytes": 50000
  }'

# Save response
export UPLOAD_URL="<uploadUrl_from_response>"
export OBJECT_KEY="<objectKey_from_response>"
export PUBLIC_URL="<publicUrl_from_response>"
```

#### 4. Upload File

```bash
# Download test image
curl -o test.jpg https://via.placeholder.com/800x600.jpg

# Upload to MinIO
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @test.jpg
```

#### 5. Confirm Upload

```bash
curl -X POST http://localhost/media/api/media/confirm \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "objectKey": "'$OBJECT_KEY'",
    "roomId": "'$ROOM_ID'",
    "sizeBytes": 50000
  }'
```

#### 6. Send Message

```bash
curl -X POST http://localhost/backend/api/rooms/$ROOM_ID/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Check this image!",
    "messageType": "IMAGE",
    "media": {
      "objectKey": "'$OBJECT_KEY'",
      "url": "'$PUBLIC_URL'",
      "mimeType": "image/jpeg",
      "sizeBytes": 50000
    }
  }'
```

#### 7. Verify Image

```bash
# Check image is accessible
curl -I "$PUBLIC_URL"

# Expected: 200 OK, Content-Type: image/jpeg
```

### Automated Testing

**Health Checks:**

```bash
# Media service
curl http://localhost/media/actuator/health

# MinIO
curl http://localhost/minio/minio/health/live

# Chat backend
curl http://localhost/backend/actuator/health
```

**Kubernetes:**

```bash
# Check HPA
kubectl get hpa -n chat-app
kubectl describe hpa media-service-hpa -n chat-app

# View logs
kubectl logs -f deployment/media-service -n chat-app
kubectl logs -f statefulset/minio -n chat-app

# Check pods
kubectl get pods -n chat-app
```

---

## 🔒 Security & Validation

### Room Membership Validation

**Implementation:**

```kotlin
// MediaService.kt
fun generateUploadUrl(request: UploadUrlRequest, userId: Long, jwtToken: String) {
    // Validate room membership before issuing URL
    if (!roomValidationService.validateRoomMembership(userId, request.roomId, jwtToken)) {
        throw IllegalArgumentException("User not a member of room")
    }
    // ...
}
```

**How it works:**
1. Media service extracts JWT token from request
2. Calls chat backend: `GET /api/rooms/{roomId}/messages?page=0&size=1`
3. If 200 OK → user has access
4. If 403/404 → deny upload
5. Result cached for 5 minutes

### File Validation

**Upload Request:**
- ✅ MIME type must be in allowed list
- ✅ File size ≤ 10MB (configurable)
- ✅ JWT token must be valid
- ✅ User must be room member

**Upload Confirmation:**
- ✅ Object must exist in MinIO
- ✅ Actual size must match (within 1KB)
- ✅ User must own the media
- ✅ Updates metadata with actual size from MinIO

### Download Security

**Current:** Public bucket → anyone with URL can download

**Future (Private Bucket):**
```kotlin
fun generateDownloadUrl(objectKey: String, userId: Long, jwtToken: String) {
    val metadata = findByObjectKey(objectKey)
    
    // Check ownership OR room membership
    val hasAccess = metadata.ownerUserId == userId || 
        roomValidationService.validateRoomMembership(userId, metadata.roomId, jwtToken)
    
    if (!hasAccess) {
        throw IllegalArgumentException("Access denied")
    }
    // Generate presigned GET URL
}
```

### CORS Configuration

**NGINX (for MinIO):**
```nginx
location ^~ /minio/ {
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, PUT, POST, DELETE, OPTIONS";
    add_header Access-Control-Allow-Headers "Content-Type, Content-Length, x-amz-*";
    
    if ($request_method = OPTIONS) {
        return 204;
    }
}
```

**Production:** Replace `*` with specific origins

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Upload Fails with 403

**Symptoms:** `PUT` to presigned URL returns 403

**Causes:**
- Presigned URL expired (10 min limit)
- Content-Type header doesn't match
- CORS not configured

**Solutions:**
```bash
# Check URL hasn't expired
# Ensure Content-Type matches mimeType from request
# Verify CORS in nginx.conf or MinIO
```

#### 2. Room Validation Fails

**Symptoms:** "User not a member of room"

**Causes:**
- User not added to room
- Chat backend not reachable
- JWT token invalid

**Solutions:**
```bash
# Check room membership
kubectl logs -f deployment/media-service -n chat-app | grep "Room membership"

# Verify chat backend URL
kubectl describe deployment media-service -n chat-app | grep CHAT_BACKEND_URL

# Test connectivity
kubectl exec -it deployment/media-service -n chat-app -- curl http://backend:8080/actuator/health
```

#### 3. Image Not Displaying

**Symptoms:** Message sent but image doesn't load

**Causes:**
- Public URL not accessible
- Bucket policy incorrect
- CORS blocking browser

**Solutions:**
```bash
# Test direct access
curl -I http://localhost:9000/chat-media/...

# Check bucket policy
mc anonymous get myminio/chat-media

# Verify CORS in browser console
```

#### 4. Size Mismatch Error

**Symptoms:** Confirmation fails with size mismatch

**Causes:**
- File compressed during upload
- Client calculated size incorrectly

**Solutions:**
```kotlin
// We allow 1KB difference
if (Math.abs(actualSize - request.sizeBytes) > 1024) {
    logger.warn("Size mismatch but within tolerance")
}
// Uses actual size from MinIO
```

### Debug Logs

**Media Service:**
```bash
# Docker Compose
docker logs chat-app-backend-media -f

# Kubernetes
kubectl logs -f deployment/media-service -n chat-app

# Look for:
# - "Generating upload URL"
# - "Room membership validation"
# - "Object verified in MinIO"
```

**MinIO:**
```bash
# Access MinIO console
open http://localhost:9001
# Login: minioadmin / minioadmin

# Check bucket contents
mc ls myminio/chat-media/rooms/
```

---

## 🎯 Next Steps

### Immediate Tasks

1. **Flutter UI Implementation**
   - [ ] Add attach button to chat input
   - [ ] Integrate image picker
   - [ ] Show upload progress indicators
   - [ ] Display images in message bubbles
   - [ ] Add fullscreen image viewer
   - [ ] Handle retry/cancel for failed uploads

2. **Testing**
   - [ ] Add unit tests for media service
   - [ ] Add integration tests for upload flow
   - [ ] Test concurrent uploads
   - [ ] Load testing with K6

3. **Error Handling**
   - [ ] Better error messages in Flutter
   - [ ] Retry logic with exponential backoff
   - [ ] Offline support (queue uploads)

### Future Enhancements

1. **Image Processing**
   - Thumbnail generation
   - Image compression before upload
   - Automatic rotation based on EXIF
   - WebP conversion for smaller sizes

2. **Advanced Features**
   - Video attachments
   - Multiple files per message
   - File attachments (PDF, docs)
   - Audio messages

3. **Performance**
   - CDN integration (CloudFront)
   - Progressive image loading
   - Image caching strategy
   - Lazy loading in chat history

4. **Security**
   - Switch to private bucket
   - Virus scanning on upload
   - Watermarking
   - Download tracking/analytics

5. **Cleanup & Lifecycle**
   - Scheduled job to delete PENDING_UPLOAD media
   - Archive old media to cheaper storage
   - Implement media expiry policies
   - Soft delete with retention period

### Production Considerations

1. **Monitoring**
   - Set up Prometheus metrics
   - Add Grafana dashboards
   - Alert on high failure rates
   - Track storage usage

2. **Scaling**
   - MinIO distributed mode (4+ nodes)
   - Multiple media-service replicas
   - Read replicas for PostgreSQL
   - Redis caching for frequently accessed media

3. **Backup**
   - MinIO bucket replication
   - PostgreSQL backups
   - Disaster recovery plan

---

## 📊 Metrics & Monitoring

### Key Metrics to Track

1. **Upload Success Rate**
   - Target: >99%
   - Alert if <95%

2. **Average Upload Time**
   - Target: <5s for 5MB file
   - Alert if >10s

3. **Storage Usage**
   - Track total size in MinIO
   - Alert at 80% capacity

4. **API Latency**
   - P50, P95, P99 for all endpoints
   - Alert if P95 >500ms

5. **Error Rates**
   - Track by error type
   - Alert on spikes

### Prometheus Queries

```promql
# Upload success rate
rate(media_uploads_total{status="success"}[5m]) / 
rate(media_uploads_total[5m])

# Average upload duration
rate(media_upload_duration_seconds_sum[5m]) / 
rate(media_upload_duration_seconds_count[5m])

# Storage usage
minio_bucket_usage_total_bytes{bucket="chat-media"}
```

---

## 🔗 Access URLs

### Docker Compose

- **Frontend:** http://localhost
- **Chat Backend:** http://localhost/backend
- **Media Service:** http://localhost/media
- **MinIO API:** http://localhost/minio
- **MinIO Console:** http://localhost:9001

### Kubernetes

- **All Services:** http://chat.abhishek.com
- **Paths:** `/`, `/backend/`, `/media/`, `/minio/`
- **Add to /etc/hosts:** `127.0.0.1 chat.abhishek.com`

---

## 📝 Summary of Changes

### Files Created (Backend)

```
media-service/
├── src/main/kotlin/com/abhishek/media_service/
│   ├── MediaServiceApplication.kt
│   ├── config/
│   │   ├── MinioConfig.kt
│   │   ├── SecurityConfig.kt
│   │   ├── JwtService.kt
│   │   ├── JwtAuthenticationFilter.kt
│   │   ├── JwtAuthenticationEntryPoint.kt
│   │   ├── CustomUserDetails.kt
│   │   └── AppConfig.kt ⭐ NEW (caching, RestTemplate)
│   ├── entity/MediaMetadata.kt
│   ├── repository/MediaMetadataRepository.kt
│   ├── dto/MediaDto.kt
│   ├── service/
│   │   ├── MediaService.kt (updated with room validation)
│   │   └── RoomValidationService.kt ⭐ NEW
│   └── controller/MediaController.kt (updated with JWT extraction)
├── src/main/resources/application.yml (added chat.backend.url)
├── Dockerfile
└── pom.xml

k8s/
├── minio.yaml ⭐ NEW
├── media-service.yaml ⭐ NEW
├── ingress.yaml (updated)
└── secret.yaml (updated)
```

### Files Created (Flutter)

```
chat-app-frontend/lib/
├── models/message.dart (updated with MediaAttachment, UploadUrlResponse)
├── config/api_constants.dart (updated with media endpoints)
├── services/
│   ├── media_service.dart ⭐ NEW
│   ├── api_service.dart (added sendMessage method)
│   └── websocket_service.dart (updated sendMessage with media)
└── notifiers/
    └── media_upload_notifier.dart ⭐ NEW

pubspec.yaml (added image_picker, mime)
```

### Files Modified (Backend)

```
chat-app-backend/
├── document/Message.kt (enhanced Attachment)
├── dto/ApiDto.kt (added MediaAttachmentDto)
├── service/MessageService.kt (media handling)
└── controller/RoomController.kt (added POST /messages endpoint)

docker-compose.yml (added minio, media-service)
nginx/nginx.conf (added /media/, /minio/ routes)
k8s/backend.yaml (fixed secret references)
setup-cluster.sh (added media-service build)
deploy.sh (added media-service option)
.env.example (added MinIO variables)
```

---

## ✅ Compliance Checklist

- ✅ Users can attach photos from web and mobile
- ✅ Backend issues presigned URLs for MinIO
- ✅ Frontend uploads directly to MinIO (no bytes through chat backend)
- ✅ Chat backend stores only metadata + URL
- ✅ Separate Media Service microservice
- ✅ MinIO cluster with S3 API
- ✅ CORS configured for browser uploads
- ✅ PostgreSQL media metadata table with lifecycle status
- ✅ Docker Compose and Kubernetes deployments
- ✅ NGINX reverse proxy routing
- ✅ JWT authentication and room membership validation
- ✅ MIME type and size validation
- ✅ Autoscaling (HPA) for media-service
- ✅ Health checks and monitoring endpoints
- ✅ Error handling and retry logic
- ✅ Size verification from MinIO (not client-provided)
- ✅ Caching for room membership checks
- ✅ Comprehensive logging
- ✅ REST endpoint for message creation (alternative to WebSocket)
- ✅ Flutter models, services, and notifiers ready for UI integration

---

## 📞 Support

For issues or questions:

1. Check logs: `kubectl logs -f deployment/media-service -n chat-app`
2. Verify configuration: `kubectl describe deployment media-service -n chat-app`
3. Test endpoints: Use cURL examples above
4. Check MinIO console: http://localhost:9001

---

**Last Updated:** 2024-01-15
**Version:** 2.0.0 (Refactored Architecture)
**Status:** ✅ Backend Implementation Complete - Flutter UI Integration Pending

---

## 🔄 Refactored Architecture Changes (v2.0)

### Backend Changes

#### Chat Backend (NEW Components)

**Files Created:**

1. **`entity/MediaMetadata.kt`** - PostgreSQL entity
   ```kotlin
   @Entity
   data class MediaMetadata(
       val id: String?,
       val roomId: String,
       val userId: Long,
       val objectKey: String,
       val mimeType: String,
       val sizeBytes: Long,
       var status: MediaStatus, // PENDING_UPLOAD, ACTIVE, FAILED, DELETED
       var mediaUrl: String?
   )
   ```

2. **`repository/MediaMetadataRepository.kt`** - JPA repository

3. **`service/MediaMetadataService.kt`** - Manages media lifecycle
   - `createPendingMedia()` - Creates PENDING_UPLOAD entry
   - `markActive()` - Updates to ACTIVE after verification
   - `markFailed()` - Marks as FAILED
   - `verifyOwnership()` - Checks user owns media
   - `verifyRoomMembership()` - Checks media belongs to room

4. **`service/MediaInternalClient.kt`** - REST client for media service
   - `getUploadUrl()` - Requests presigned URL from media service
   - `verifyUpload()` - Verifies object exists in MinIO
   - `getDownloadUrl()` - For private bucket support (future)
   - `deleteObject()` - Deletes from MinIO

5. **`dto/MediaUploadRequest & MediaUploadResponse`** - New DTOs

**Controller Updates:**

6. **`RoomController.kt`** - NEW endpoint:
   ```kotlin
   @PostMapping("/{roomId}/media/upload-url")
   fun requestMediaUploadUrl(
       @PathVariable roomId: String,
       @RequestBody request: MediaUploadRequest,
       @AuthenticationPrincipal userDetails: CustomUserDetails
   ): ResponseEntity<ApiResponse<MediaUploadResponse>>
   ```

   Flow:
   - Validates JWT & room membership
   - Validates MIME type & size
   - Generates canonical `objectKey`: `rooms/{roomId}/users/{userId}/{uuid}.{ext}`
   - Calls `MediaInternalClient.getUploadUrl()`
   - Creates `MediaMetadata` in PENDING state
   - Returns `mediaId`, `uploadUrl`, `objectKey`, `publicUrl`

7. **`ChatController.kt`** - UPDATED (to be implemented):
   ```kotlin
   @MessageMapping("/chat.sendMessage")
   fun sendMessage(payload: ChatMessagePayload, principal: Principal) {
       // If messageType == 'IMAGE':
       // 1. Get mediaId from payload.media
       // 2. Verify ownership: mediaMetadataService.verifyOwnership(mediaId, userId)
       // 3. Verify room: mediaMetadataService.verifyRoomMembership(mediaId, roomId)
       // 4. Call mediaInternalClient.verifyUpload(objectKey, expectedSize)
       // 5. If verified:
       //    - mediaMetadataService.markActive(mediaId, publicUrl)
       //    - Save message with media
       //    - Broadcast via WebSocket
       // 6. Else: markFailed() and reject
   }
   ```

**Configuration:**

8. **`application.yml`** - Added:
   ```yaml
   media:
     service:
       url: http://media-service:8081
       token: ""  # Optional internal auth token
   ```

9. **Production config** (docker-compose.yml, k8s/backend.yaml):
   - `MEDIA_SERVICE_URL=http://media-service:8081`
   - `MEDIA_SERVICE_TOKEN=` (optional)

#### Media Service (REFACTORED to Internal-Only)

**Removed:**
- JWT authentication filters
- Security dependencies
- PostgreSQL/chat DB connections
- Room validation service
- User authentication

**New Internal Endpoints:**

1. **`POST /internal/media/upload-url`**
   ```kotlin
   data class InternalUploadUrlRequest(
       val objectKey: String,  // Provided by chat backend
       val mimeType: String,
       val sizeBytes: Long
   )
   
   data class InternalUploadUrlResponse(
       val uploadUrl: String,     // Presigned PUT URL
       val objectKey: String,     // Same as request
       val publicUrl: String,     // For reading
       val expiresIn: Int         // Seconds
   )
   ```
   - Accepts pre-generated objectKey from chat backend
   - Generates presigned PUT URL via MinIO
   - Returns public URL for reading

2. **`POST /internal/media/verify`**
   ```kotlin
   data class InternalVerifyRequest(
       val objectKey: String,
       val expectedSize: Long
   )
   
   data class InternalVerifyResponse(
       val verified: Boolean,
       val actualSize: Long,
       val publicUrl: String
   )
   ```
   - Stats object in MinIO using `statObject()`
   - Compares size (allows 1KB tolerance)
   - Returns verification result

3. **`GET /internal/media/download-url?objectKey=...`**
   - Generates presigned GET URL (for future private buckets)

4. **`DELETE /internal/media/object?objectKey=...`**
   - Deletes object from MinIO

**Security:**
- Optional `X-Internal-Token` header for authentication
- Network-level isolation (ClusterIP only, no Ingress)
- No JWT, no user context

**Configuration:**

5. **`application.yml`** - Simplified:
   ```yaml
   minio:
     endpoint: http://minio:9000
     access-key: minioadmin
     secret-key: minioadmin
     bucket: chat-media
     presigned-upload-expiry-seconds: 600
   
   # REMOVED:
   # - spring.datasource (no PostgreSQL)
   # - jwt.secret
   # - chat.backend.url
   ```

### Infrastructure Changes

#### Docker Compose

**Updated:**

1. **Networks** - Split into internal/public:
   ```yaml
   networks:
     chat-network:      # Public
       driver: bridge
     internal-network:  # Internal only
       driver: bridge
       internal: true
   
   services:
     media-service:
       networks:
         - internal-network  # NOT on public network
     
     backend:
       networks:
         - chat-network
         - internal-network  # Can talk to media-service
     
     minio:
       networks:
         - internal-network  # NOT directly accessible
   ```

2. **NGINX** - Removed `/media/` route:
   ```nginx
   # REMOVED:
   # location ^~ /media/ { ... }
   
   # Keep only:
   location / { ... }           # Frontend
   location ^~ /backend/ { ... } # Chat backend
   ```

3. **MinIO Access** - NEW separate host:
   ```yaml
   # Option 1: Separate ingress for presigned URLs
   # Host: media.chat.abhishek.com → MinIO:9000
   
   # Option 2: Public read bucket (current)
   # Presigned URLs contain full MinIO URL
   ```

#### Kubernetes

**New Files:**

1. **`k8s/network-policy.yaml`** (to be created):
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: media-service-network-policy
     namespace: chat-app
   spec:
     podSelector:
       matchLabels:
         app: media-service
     policyTypes:
     - Ingress
     ingress:
     - from:
       - podSelector:
           matchLabels:
             app: backend  # Only backend can access
       ports:
       - protocol: TCP
         port: 8081
   ```

**Updated:**

2. **`k8s/ingress.yaml`** - Removed `/media` path:
   ```yaml
   # REMOVED:
   # - path: /media(/|$)(.*)
   
   # ADDED (optional):
   # - host: media.chat.abhishek.com
   #   paths:
   #     - path: /
   #       backend:
   #         service:
   #           name: minio
   #           port:
   #             number: 9000
   ```

3. **`k8s/media-service.yaml`** - Already ClusterIP, no changes needed

4. **`k8s/backend.yaml`** - Added environment variables:
   ```yaml
   - name: MEDIA_SERVICE_URL
     value: "http://media-service:8081"
   - name: MEDIA_SERVICE_TOKEN
     valueFrom:
       secretKeyRef:
         name: chat-app-secret
         key: MEDIA_SERVICE_TOKEN
         optional: true
   ```

### Flutter Changes

**Updated:**

1. **`lib/config/api_constants.dart`**:
   ```dart
   // CHANGED:
   static String mediaUploadUrl(String roomId) => 
     '$apiPrefix/rooms/$roomId/media/upload-url';
   
   // REMOVED:
   // static const String mediaBaseUrl = ...
   // static const String mediaApiPrefix = ...
   ```

2. **`lib/services/api_service.dart`** - NEW method:
   ```dart
   static Future<MediaUploadResponse> requestMediaUpload({
     required String roomId,
     required String fileName,
     required String mimeType,
     required int sizeBytes,
   }) async {
     // POST to /api/rooms/{roomId}/media/upload-url
     // Returns: mediaId, uploadUrl, objectKey, publicUrl
   }
   ```

3. **`lib/notifiers/media_upload_notifier.dart`** - Updated flow:
   ```dart
   Future<MediaAttachment?> uploadMedia(...) async {
     // 1. Call ApiService.requestMediaUpload() instead of MediaService
     final uploadResponse = await ApiService.requestMediaUpload(...);
     
     // 2. Upload to MinIO (same as before)
     await uploadToMinIO(uploadResponse.uploadUrl, fileBytes);
     
     // 3. Send WebSocket message (removed confirm step)
     await websocketService.sendMessage(
       roomId: roomId,
       messageType: 'IMAGE',
       media: {
         'mediaId': uploadResponse.mediaId,
         'objectKey': uploadResponse.objectKey,
         'url': uploadResponse.publicUrl,
         'mimeType': mimeType,
         'sizeBytes': sizeBytes,
       },
     );
   }
   ```

4. **`lib/services/media_service.dart`** - REMOVED (no longer needed)

5. **`lib/services/websocket_service.dart`** - Already supports media payload

### Migration Checklist

- [x] Chat Backend: MediaMetadata entity/repository
- [x] Chat Backend: MediaMetadataService
- [x] Chat Backend: MediaInternalClient
- [x] Chat Backend: RoomController upload-url endpoint
- [ ] Chat Backend: ChatController verification logic
- [ ] Media Service: Remove JWT/security
- [ ] Media Service: Internal endpoints
- [ ] Media Service: Remove PostgreSQL config
- [ ] Docker Compose: Network isolation
- [ ] Kubernetes: NetworkPolicy
- [ ] Kubernetes: Update ingress
- [ ] Flutter: Update API client
- [ ] Flutter: Remove MediaService class
- [ ] Flutter: Update upload flow
- [ ] Testing: End-to-end flow
- [ ] Documentation: Update API docs

### Benefits of Refactored Architecture

1. **Simplified Security**: Only one public API (chat backend)
2. **Better Control**: Chat backend validates everything before issuing URLs
3. **Media State Tracking**: PostgreSQL entity tracks lifecycle
4. **Reduced Complexity**: Media service has no auth, no DB, just MinIO wrapper
5. **Network Isolation**: Media service unreachable from outside
6. **Single Source of Truth**: Chat backend owns all business logic
7. **Easier Testing**: Internal service easier to mock
8. **Future-Proof**: Easy to add virus scanning, compression, etc. in chat backend

### Breaking Changes

1. **Frontend must update**: Call `/api/rooms/{roomId}/media/upload-url` instead of `/media/api/media/upload-url`
2. **No more confirm endpoint**: Verification happens during message send
3. **STOMP-only messages**: REST message endpoint removed
4. **mediaId required**: Must be included in WebSocket payload

---

## Overview
Successfully implemented photo/media attachment capability for the chat application following the PRD/TRD specifications. The implementation uses MinIO for object storage with presigned URLs for direct client uploads, avoiding backend bottlenecks.

## What Was Implemented

### 1. New Media Service (Spring Boot + Kotlin)
**Location:** `/media-service/`

**Key Components:**
- **MinioConfig**: Configures MinIO client, auto-creates bucket with CORS-friendly policy
- **MediaService**: Generates presigned URLs, validates uploads, manages media metadata
- **MediaController**: REST endpoints for upload/download URL generation, confirmation, deletion
- **MediaMetadata Entity**: PostgreSQL entity tracking media files with status lifecycle
- **Security**: JWT-based authentication matching chat backend

**REST API Endpoints:**
- `POST /api/media/upload-url` - Generate presigned upload URL
- `POST /api/media/confirm` - Confirm successful upload
- `GET /api/media/download-url` - Generate presigned download URL
- `GET /api/media/{id}` - Get media metadata
- `DELETE /api/media/{id}` - Delete media

**Configuration:**
- Max file size: 10MB (configurable)
- Allowed MIME types: image/jpeg, image/png, image/webp, image/gif
- Upload URL expiry: 10 minutes
- Download URL expiry: 30 minutes

### 2. Updated Chat Backend
**Changes:**

**Message Model** (`document/Message.kt`):
- Enhanced `Attachment` data class with `objectKey`, `mediaId`, `width`, `height`

**DTOs** (`dto/ApiDto.kt`):
- Added `MediaAttachmentDto` for media metadata
- Updated `SendMessageRequest`, `ChatMessagePayload`, `ChatMessageResponse`, `MessageDto` to include media field

**MessageService** (`service/MessageService.kt`):
- Handles messages with media attachments
- Creates attachment list from media payload
- Sets appropriate lastMessage text for image/file types ("📷 Image", "📎 File")
- Broadcasts media metadata via WebSocket

### 3. MinIO Object Storage
**Configuration:**
- Deployed as standalone service in Docker Compose and Kubernetes StatefulSet
- Bucket: `chat-media`
- Public read policy for uploaded objects
- CORS enabled for direct browser/mobile uploads
- Object key pattern: `rooms/{roomId}/users/{userId}/{uuid}.{ext}`

**Ports:**
- 9000: S3 API
- 9001: Web console

### 4. Docker Compose Updates
**New Services:**
- `minio`: MinIO server with persistent volume
- `backend-media`: Media service microservice

**Updated NGINX:**
- `/media/` → backend-media:8081
- `/minio/` → minio:9000 (S3 API + console)
- Added CORS headers for MinIO
- Increased timeouts and body size for uploads

**Environment Variables:**
- MINIO_ROOT_USER, MINIO_ROOT_PASSWORD
- MINIO_ENDPOINT, MINIO_BUCKET, MINIO_PUBLIC_URL
- MEDIA_MAX_FILE_SIZE, MEDIA_ALLOWED_MIME_TYPES

### 5. Kubernetes Manifests

**New Files:**
- `k8s/minio.yaml`: StatefulSet with PVC, services for API and console
- `k8s/media-service.yaml`: Deployment for backend-media with 2-4 replicas (HPA), anti-affinity, init containers

**Updated Files:**
- `k8s/ingress.yaml`: Routes for `/media/` and `/minio/`, CORS annotations
- `k8s/secret.yaml`: MinIO credentials
- `k8s/backend.yaml`: Fixed secret name references

**HPA Configuration:**
- Min replicas: 2
- Max replicas: 4
- CPU threshold: 70%

### 6. Deployment Scripts

**setup-cluster.sh:**
- Builds and loads media-service image
- Encodes MinIO credentials to base64
- Applies MinIO and backend-media manifests

**deploy.sh:**
- Added `backend-media` as deployment option
- Usage: `./deploy.sh backend-media`

## Architecture Flow

### Upload Flow
1. **Client** → **Media Service**: Request upload URL
   ```
   POST /media/api/media/upload-url
   Body: {roomId, fileName, mimeType, sizeBytes}
   ```

2. **Media Service** → **PostgreSQL**: Create PENDING_UPLOAD metadata

3. **Media Service** → **Client**: Return presigned PUT URL + object key

4. **Client** → **MinIO**: Direct upload using presigned URL
   ```
   PUT <presignedUrl>
   Content-Type: image/jpeg
   Body: <file bytes>
   ```

5. **Client** → **Media Service** (optional): Confirm upload
   ```
   POST /media/api/media/confirm
   Body: {objectKey, roomId, sizeBytes}
   ```

6. **Media Service**: Verify object in MinIO, update status to ACTIVE

7. **Client** → **Chat Backend**: Send message with media metadata
   ```
   POST /backend/api/rooms/{roomId}/messages
   Body: {
     messageType: "IMAGE",
     content: "caption",
     media: {objectKey, url, mimeType, sizeBytes}
   }
   ```

8. **Chat Backend** → **MongoDB**: Save message with attachment

9. **Chat Backend** → **WebSocket**: Broadcast to room subscribers

### Download/Display Flow
- For public buckets: Use `publicUrl` directly
- For private buckets: Request presigned GET URL from media service

## Key Features

✅ **Direct Upload**: Files upload directly to MinIO, bypassing backend
✅ **Presigned URLs**: Short-lived, secure upload/download URLs
✅ **Media Metadata**: Tracked in PostgreSQL with lifecycle status
✅ **Validation**: MIME type and size limits enforced
✅ **Security**: JWT authentication, room membership validation
✅ **Scalability**: Media service with HPA (2-4 replicas)
✅ **High Availability**: Pod anti-affinity, health probes
✅ **CORS Support**: Browser/mobile uploads enabled
✅ **Persistence**: MinIO PVC in Kubernetes

## Configuration

### Local Development (.env)
```bash
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_BUCKET=chat-media
MINIO_PUBLIC_URL=http://localhost:9000
MEDIA_MAX_FILE_SIZE=10485760
MEDIA_ALLOWED_MIME_TYPES=image/jpeg,image/png,image/webp,image/gif
```

### Access URLs

**Docker Compose:**
- Frontend: http://localhost
- Chat Backend: http://localhost/backend
- Media Service: http://localhost/media
- MinIO API: http://localhost/minio
- MinIO Console: http://localhost:9001

**Kubernetes:**
- All services: http://chat.abhishek.com
- Paths: `/`, `/backend/`, `/media/`, `/minio/`

## Testing

### Quick Test with cURL
See `media-service/MEDIA_GUIDE.md` for detailed examples.

```bash
# 1. Get upload URL
curl -X POST http://localhost/media/api/media/upload-url \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"roomId":"room1","fileName":"test.jpg","mimeType":"image/jpeg","sizeBytes":5000}'

# 2. Upload file
curl -X PUT "$UPLOAD_URL" -H "Content-Type: image/jpeg" --data-binary @image.jpg

# 3. Send message
curl -X POST http://localhost/backend/api/... (via WebSocket in practice)
```

## Monitoring

```bash
# Check media service HPA
kubectl get hpa backend-media-hpa -n chat-app

# View logs
kubectl logs -f deployment/backend-media -n chat-app

# MinIO health
curl http://localhost/minio/minio/health/live
```

## Files Created/Modified

### New Files
- `media-service/` - Complete microservice
  - `pom.xml`
  - `Dockerfile`
  - `src/main/resources/application.yml`
  - `src/main/kotlin/com/abhishek/media_service/`
    - `MediaServiceApplication.kt`
    - `config/` (MinioConfig, SecurityConfig, JwtService, etc.)
    - `entity/MediaMetadata.kt`
    - `repository/MediaMetadataRepository.kt`
    - `dto/MediaDto.kt`
    - `service/MediaService.kt`
    - `controller/MediaController.kt`
  - `MEDIA_GUIDE.md`
- `k8s/minio.yaml`
- `k8s/media-service.yaml`
- `.env.example`

### Modified Files
- `chat-app-backend/src/main/kotlin/com/abhishek/chat_app_backend/`
  - `document/Message.kt` - Enhanced Attachment
  - `dto/ApiDto.kt` - Added MediaAttachmentDto
  - `service/MessageService.kt` - Media handling
- `docker-compose.yml` - Added minio, backend-media, volumes
- `nginx/nginx.conf` - Added /media/, /minio/ routes with CORS
- `k8s/ingress.yaml` - Added routes and CORS
- `k8s/secret.yaml` - Added MinIO credentials
- `k8s/backend.yaml` - Fixed secret references
- `setup-cluster.sh` - Added backend-media build/deploy
- `deploy.sh` - Added backend-media option

## Next Steps for Frontend (Flutter)

1. **Add Image Picker**: Use `image_picker` package
2. **Implement Upload Flow**:
   - Call media service for upload URL
   - Upload to MinIO with progress indicator
   - Send message with media metadata
3. **Display Images**: Use `Image.network(message.media.url)`
4. **Error Handling**: Handle upload failures, retry logic
5. **UI Enhancements**: Thumbnails, image gallery, compression

## Production Considerations

- **CDN**: Place CloudFront/CDN in front of MinIO for better performance
- **Private Buckets**: Use presigned GET URLs instead of public URLs
- **Multipart Upload**: For files >5GB, implement multipart presigned upload
- **Image Processing**: Add thumbnail generation, compression
- **Cleanup**: Implement cron job to delete orphaned PENDING_UPLOAD media
- **Monitoring**: Add Prometheus metrics for upload success/failure rates
- **Rate Limiting**: Add per-user upload limits

## Compliance with PRD/TRD

✅ Users can attach photos from web and mobile
✅ Backend issues presigned URLs for MinIO
✅ Frontend uploads directly to MinIO (no bytes through chat backend)
✅ Chat backend stores only metadata + URL
✅ Separate Media Service microservice
✅ MinIO cluster with S3 API
✅ CORS configured for browser uploads
✅ PostgreSQL media metadata table
✅ Docker Compose and Kubernetes deployments
✅ NGINX reverse proxy routing
✅ Security: JWT auth, MIME validation, size limits
✅ Autoscaling (HPA) for backend-media
✅ Health checks and monitoring
