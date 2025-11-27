class Room {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<int> participants;
  final int createdBy;
  final DateTime createdAt;
  String? lastMessage;
  DateTime? lastMessageTime;
  int unreadCount;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      type: json['type'],
      participants: List<int>.from(json['participants']),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  Room copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<int>? participants,
    int? createdBy,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
