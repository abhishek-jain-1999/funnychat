class AppConstants {
  // App Info
  static const String appName = 'FlashChat';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int messagesPerPage = 20;
  static const int roomsPerPage = 50;
  
  // Layout Breakpoints
  static const double largeScreenWidth = 800.0;
  static const double chatListWidth = 450.0;
  static const double headerHeight = 60.0;
  
  // Storage Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  
  // Message Types
  static const String messageTypeText = 'TEXT';
  static const String messageTypeImage = 'IMAGE';
  static const String messageTypeFile = 'FILE';
  static const String messageTypeVoice = 'VOICE';
  
  // Room Types
  static const String roomTypeOneToOne = 'ONE_TO_ONE';
  static const String roomTypeGroup = 'GROUP';
  
  // Timeouts (in seconds)
  static const int apiTimeout = 30;
  static const int wsReconnectDelay = 5;
  
  // UI
  static const double maxMessageWidth = 0.7; // 70% of screen width
  static const double avatarRadius = 20.0;
  static const double messageBubbleRadius = 8.0;
}
