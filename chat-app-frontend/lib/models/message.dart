class Message {
  final String id;
  final String roomId;
  final int senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool edited;
  final bool isUserSelf;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.edited = false,
    this.isUserSelf = false,
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

  ChatMessageResponse({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.createdAt,
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
    };
  }

}
