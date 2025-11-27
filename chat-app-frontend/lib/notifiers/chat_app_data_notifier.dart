import 'package:chat_app_frontend/models/message.dart';
import 'package:chat_app_frontend/models/user.dart';
import 'package:chat_app_frontend/services/api_service.dart';
import 'package:chat_app_frontend/services/log_service.dart';
import 'package:flutter/cupertino.dart';

import '../models/room.dart';
import '../services/websocket_service.dart';
import 'list_notifier.dart';

class ChatAppDataNotifier {
  late final WebSocketService _wsService = WebSocketService(roomUpdateCallback, roomChatMessageCallback);

  ListNotifier<Room> listRoomsNotifier = ListNotifier();
  ListNotifier<Message> messageNotifier = ListNotifier();


  ValueNotifier<Room?> roomsNotifier = ValueNotifier(null);
  ValueNotifier<bool> profileVisible = ValueNotifier(false);
  ValueNotifier<bool> readyNotifier = ValueNotifier(false);

  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> start(User? currentUser, List<Room> result) async {
    LogService.info('WebSocket: start...');
    _currentUser = currentUser;
    listRoomsNotifier.value = result;
    await _wsService.connect(currentUser?.id);
    readyNotifier.value= true;
  }

  void roomChatMessageCallback(ChatMessageResponse chatMessage) {
    messageNotifier.add(Message(
      id: chatMessage.id,
      roomId: chatMessage.roomId,
      senderId: chatMessage.senderId,
      content: chatMessage.content,
      messageType: chatMessage.messageType,
      createdAt: chatMessage.createdAt,
      isUserSelf: chatMessage.senderId == _currentUser?.id,
    ));
  }

  void roomSelected(Room room) {
    roomsNotifier.value = room;
    profileVisible.value = false;
    _wsService.subscribeToRoom(room.id);
    _loadMessages(room);
  }

  Future<void> _loadMessages(Room room) async {
    try {
      final messages = await ApiService.getRoomMessages(roomId: room.id);
      messageNotifier.value = messages.reversed.toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }


  void roomUpdateCallback(Map<String, dynamic> update) {
    final type = update['type'] as String?;
    final roomId = update['roomId'] as String?;

    if (type == 'ROOM_CREATED') {
      // Handle new room creation
      if (update['room'] != null) {
        try {
          final newRoom = Room.fromJson(update['room'] as Map<String, dynamic>);

          // Check if room already exists
          final existingIndex = listRoomsNotifier.value.indexWhere((r) => r.id == newRoom.id);
          if (existingIndex == -1) {
            // Add new room to top of list

            listRoomsNotifier.pushChanges((rooms) {
              rooms.insert(0, newRoom);

              // If this room was just created by current user, auto-select it
              if (newRoom.createdBy == _currentUser?.id) {
                roomsNotifier.value = newRoom;
                messageNotifier.clear();
                _wsService.subscribeToRoom(newRoom.id);
              }
            });
          }
        } catch (e) {
          debugPrint('Error parsing new room: $e');
        }
      }
    } else if (type == 'MESSAGE_SENT' && roomId != null) {
      // Handle message sent - update room's last message
      final lastMessage = update['lastMessage'] as String?;
      final lastMessageTimeStr = update['lastMessageTime'] as String?;
      // final senderName = update['senderName'] as String?;

      final roomIndex = listRoomsNotifier.value.indexWhere((r) => r.id == roomId);

      if (roomIndex != -1) {
        listRoomsNotifier.pushChanges((rooms) {
          final updatedRoom = rooms[roomIndex].copyWith(
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTimeStr != null ? DateTime.parse(lastMessageTimeStr) : null,
          );

          // Move room to top (most recent)
          rooms.removeAt(roomIndex);
          rooms.insert(0, updatedRoom);
        });
      }
    } else if (type == 'UNREAD_UPDATE') {
      // Handle unread count updates if needed in future
      debugPrint('Unread update received for room: $roomId');
    }
  }

  void sendMessage({
    required String content,
  }) {
    if (roomsNotifier.value == null) return;
    _wsService.sendMessage(
      roomId: roomsNotifier.value!.id,
      content: content,
    );
  }

  void dispose() {
    listRoomsNotifier.dispose();
    roomsNotifier.dispose();
    messageNotifier.dispose();
    _wsService.disconnect();
  }
}
