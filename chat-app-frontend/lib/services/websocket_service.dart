import 'dart:convert';
import 'package:chat_app_frontend/utils/extension.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../config/api_constants.dart';
import '../models/message.dart';
import 'api_service.dart';
import 'log_service.dart';


class StompUnsubscribeManager {
  final StompUnsubscribe? unsubscribe;
  final Map<String, String> headers;

  StompUnsubscribeManager(this.unsubscribe, this.headers);

  void dispose() {
    LogService.info('WebSocket: UnSubscribed to room ${headers['id']}');
    unsubscribe?.call(unsubscribeHeaders: headers);
  }
}

class WebSocketService {


  StompClient? _stompClient;
  StompUnsubscribeManager? _roomUpdateSubscriptionManager;
  StompUnsubscribeManager? _roomChatMessageSubscriptionManager;
  bool _isConnected = false;

  bool get isConnected => _isConnected;


  Function(Map<String, dynamic>)? roomUpdateCallback;
  Function(ChatMessageResponse)? roomChatMessageCallback;

  int? _userId;

  WebSocketService(
    this.roomUpdateCallback,
    this.roomChatMessageCallback,
  );

  Future<void> connect(int? userId) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    _userId = userId;

    final wsUrl = '${ApiConstants.baseUrl}${ApiConstants.wsEndpoint}'.withHostUrl();

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        useSockJS: true,
        onConnect: _onConnect,
        beforeConnect: () async {
          LogService.info('WebSocket: Connecting... ${ApiConstants.baseUrl}${ApiConstants.wsEndpoint}');
        },
        onWebSocketError: (dynamic error) {
          LogService.error('WebSocket Error: $error');
          _isConnected = false;
        },
        onStompError: (StompFrame frame) {
          LogService.error('STOMP Error: ${frame.body}');
          _isConnected = false;
        },
        onDisconnect: (StompFrame frame) {
          LogService.info('WebSocket: Disconnected');
          _isConnected = false;
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    LogService.info('WebSocket: Connected');
    _isConnected = true;

    // Send addUser message
    _stompClient!.send(
      destination: ApiConstants.addUserDest,
      body: jsonEncode({}),
    );

    // Subscribe to user queue
    _stompClient!.subscribe(
      destination: ApiConstants.userQueueDest,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          LogService.info('User queue message: ${frame.body}');
        }
      },
    );
    
    // Subscribe to room updates
    _subscribeToRoomUpdates();
    // todo when new room is create should be subscribed automatically
    // todo seletion is not working correctly after new room is created
    // Subscribe to message update if already in a room
    if (_roomChatMessageSubscriptionManager != null && _roomChatMessageSubscriptionManager!.headers.containsKey('id')) {
      subscribeToRoom(_roomChatMessageSubscriptionManager!.headers['id']!);
    }
  }

  void subscribeToRoom(String roomId) {
    _roomChatMessageSubscriptionManager?.dispose();
    _roomChatMessageSubscriptionManager = null;

    if (!_isConnected || _stompClient == null) {
      LogService.warn('WebSocket: Not connected, cannot subscribe');
      return;
    }

    final destination = ApiConstants.roomTopicDest(roomId);
    LogService.info('WebSocket: Subscribed to room $roomId');

    final headers =  {"id":  roomId};


    final unsubscribe= _stompClient?.subscribe(
      destination: destination,
      headers: headers,
      callback: (StompFrame frame) {
        if (frame.body != null && roomChatMessageCallback != null) {
          try {
            final messageData = jsonDecode(frame.body!);
            final message = ChatMessageResponse.fromJson(messageData);
            roomChatMessageCallback!(message);
            LogService.info('Message update received: $message');
          } catch (e) {
            LogService.error('Error parsing message: $e');
          }
        }
      },
    );

    _roomChatMessageSubscriptionManager = StompUnsubscribeManager(unsubscribe, headers);
  }


  void sendMessage({
    required String roomId,
    required String content,
    String messageType = 'TEXT',
  }) {
    if (!_isConnected || _stompClient == null) {
      LogService.warn('WebSocket: Not connected, cannot send message');
      return;
    }

    _stompClient!.send(
      destination: ApiConstants.sendMessageDest,
      body: jsonEncode({
        'roomId': roomId,
        'content': content,
        'messageType': messageType,
      }),
    );
  }



  void _subscribeToRoomUpdates() {
    if (!_isConnected || _stompClient == null|| _userId == null) {
      LogService.warn('WebSocket: Not connected, cannot subscribe to room updates');
      return;
    }

    final headers = {"id": "user"};

    final unsubscribe = _stompClient!.subscribe(
      destination: ApiConstants.roomUpdatesQueueDest,
      headers: headers,
      callback: (StompFrame frame) {
        if (frame.body != null && roomUpdateCallback != null) {
          try {
            final updateData = jsonDecode(frame.body!);
            LogService.info('Room update received: $updateData');
            roomUpdateCallback!(updateData);
          } catch (e) {
            LogService.error('Error parsing room update: $e');
          }
        }
      },
    );

    _roomUpdateSubscriptionManager = StompUnsubscribeManager(unsubscribe, headers);

    LogService.info('WebSocket: Subscribed to room updates at ${ApiConstants.roomUpdatesQueueDest}');
  }


  void disconnect() {
    _roomUpdateSubscriptionManager?.dispose();
    _roomChatMessageSubscriptionManager?.dispose();
    _roomUpdateSubscriptionManager=null;
    _roomChatMessageSubscriptionManager=null;
    _stompClient?.deactivate();
    _isConnected = false;
  }
}
