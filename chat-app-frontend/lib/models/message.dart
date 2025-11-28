// Media message types
enum MediaMessageType {
  text,
  image,
  file,
  system;

  static MediaMessageType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return MediaMessageType.image;
      case 'FILE':
        return MediaMessageType.file;
      case 'SYSTEM':
        return MediaMessageType.system;
      default:
        return MediaMessageType.text;
    }
  }

  String toUpperCase() {
    switch (this) {
      case MediaMessageType.image:
        return 'IMAGE';
      case MediaMessageType.file:
        return 'FILE';
      case MediaMessageType.system:
        return 'SYSTEM';
      default:
        return 'TEXT';
    }
  }
}

// Media attachment model
class MediaAttachment {
  final String mediaId;
  final String? url;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;

  MediaAttachment({
    required this.mediaId,
    this.url,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      mediaId: json['mediaId'] ?? '',
      url: json['url'],
      mimeType: json['mimeType'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (url != null) 'url': url,
      'mediaId': mediaId,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}

// Upload URL response from media service
class UploadUrlResponse {
  final String uploadUrl;
  final String objectKey;
  final int expiresIn;
  final String mediaId;

  UploadUrlResponse({
    required this.uploadUrl,
    required this.objectKey,
    required this.expiresIn,
    required this.mediaId,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      uploadUrl: json['uploadUrl'],
      objectKey: json['objectKey'],
      expiresIn: json['expiresIn'],
      mediaId: json['mediaId'],
    );
  }
}

class Message {
  final String id;
  final String roomId;
  final int senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool edited;
  final bool isUserSelf;
  final MediaAttachment? media;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.edited = false,
    this.isUserSelf = false,
    this.media,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      content: json['content'],
      messageType: json['messageType'] ?? 'TEXT',
      createdAt: DateTime.parse(json['createdAt']),
      edited: json['edited'] ?? false,
      isUserSelf: json['isUserSelf'] ?? false,
      media: json['media'] != null ? MediaAttachment.fromJson(json['media']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'messageType': messageType,
      'createdAt': createdAt.toIso8601String(),
      'edited': edited,
      'isUserSelf': isUserSelf,
      if (media != null) 'media': media!.toJson(),
    };
  }

}

class ChatMessageResponse {
  final String id;
  final String roomId;
  final int senderId;
  final String senderName;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final MediaAttachment? media;

  ChatMessageResponse({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.media,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      messageType: json['messageType'],
      createdAt: DateTime.parse(json['createdAt']),
      media: json['media'] != null ? MediaAttachment.fromJson(json['media']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType,
      'createdAt': createdAt.toIso8601String(),
      if (media != null) 'media': media!.toJson(),
    };
  }

}
