class ApiConstants {
  // Update this with your backend URL
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
  static const String apiPrefix = '/api';
  
  // Auth endpoints
  static const String signup = '$apiPrefix/auth/signup';
  static const String login = '$apiPrefix/auth/login';
  static const String me = '$apiPrefix/auth/me';
  
  // Room endpoints
  static const String rooms = '$apiPrefix/rooms';
  
  // WebSocket endpoint
  static const String wsEndpoint = '/ws/chat';
  
  // STOMP destinations
  static const String sendMessageDest = '/app/chat.sendMessage';
  static const String addUserDest = '/app/chat.addUser';
  static String roomTopicDest(String roomId) => '/topic/room.$roomId';
  static const String userQueueDest = '/user/queue/reply';

  static String roomUpdatesQueueDest = '/user/queue/roomUpdates';

}
