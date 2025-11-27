# WhatsApp Clone - Flutter Frontend

A modern, responsive chat application built with Flutter, featuring a WhatsApp-inspired dark mode UI.

## Features

✅ **Authentication**
- Sign up with email, first name, last name, and password
- Sign in with email and password
- JWT token-based authentication
- Persistent login sessions

✅ **Chat Interface**
- WhatsApp-style dark mode UI
- Responsive layout (Web & Mobile)
- Real-time messaging via WebSocket (STOMP)
- Message history with pagination
- Date headers in chat
- Unread message badges
- Search functionality

✅ **User Profile**
- View and edit profile
- Profile picture support
- About/status section

✅ **Responsive Design**
- **Large Screens (>800px)**: Two-column layout (chat list + active chat)
- **Small Screens (<800px)**: Single-column layout with navigation

## Color Scheme (WhatsApp Dark Mode)

- Primary Background: `#111B21`
- Secondary Background: `#202C33`
- Accent Color: `#00A884` (Teal green)
- Text Primary: `#E9EDEF`
- Text Secondary: `#8696A0`
- Outgoing Message Bubble: `#005C4B`
- Incoming Message Bubble: `#202C33`

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.4.3)
- Backend server running on `http://localhost:8080`

### Installation

1. Navigate to the frontend directory:
```bash
cd chat-app-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API configuration (if needed):
Edit `lib/config/api_constants.dart` to change the backend URL:
```dart
static const String baseUrl = 'http://localhost:8080';
```

4. Run the app:
```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS (Mac only)
flutter run -d ios
```

## Project Structure

```
lib/
├── config/
│   ├── api_constants.dart    # API endpoints configuration
│   └── theme.dart            # App theme (colors, text styles)
├── models/
│   ├── user.dart             # User model
│   ├── room.dart             # Room/Chat model
│   └── message.dart          # Message model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart # Login UI
│   │   └── signup_screen.dart# Signup UI
│   ├── chat/
│   │   ├── chat_list_panel.dart # Left sidebar with chat list
│   │   └── chat_panel.dart      # Right panel with messages
│   ├── main_screen.dart      # Main app layout
│   └── profile_screen.dart   # User profile
├── services/
│   ├── api_service.dart      # REST API calls
│   └── websocket_service.dart# WebSocket/STOMP service
├── utils/
│   └── datetime_utils.dart   # Date/time formatting utilities
└── main.dart                 # App entry point
```

## API Integration

### REST APIs

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/signup` | POST | User registration |
| `/api/auth/login` | POST | User login |
| `/api/auth/me` | GET | Get current user |
| `/api/rooms` | GET | Get user's rooms |
| `/api/rooms` | POST | Create new room |
| `/api/rooms/{id}/messages` | GET | Get room messages |

### WebSocket

- **Connect**: `/ws/chat`
- **Send Message**: `/app/chat.sendMessage`
- **Subscribe to Room**: `/topic/room.{roomId}`
- **Add User**: `/app/chat.addUser`

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  http: ^1.1.0                # REST API calls
  shared_preferences: ^2.2.2  # Local storage
  web_socket_channel: ^2.4.0  # WebSocket support
  stomp_dart_client: ^1.0.0   # STOMP protocol
  intl: ^0.18.1               # Date/time formatting
  provider: ^6.1.1            # State management
  flutter_svg: ^2.0.9         # SVG support
```

## Screenshots

The app matches the WhatsApp dark mode design with:
- Clean, modern interface
- Smooth animations
- Intuitive navigation
- Professional color scheme

## Development Notes

### Backend Configuration

Make sure your backend is configured to:
1. Accept CORS requests from your Flutter app
2. Return proper JWT tokens on login/signup
3. Accept WebSocket connections with Authorization headers

### Testing

```bash
# Run tests
flutter test

# Run with verbose output
flutter test --verbose
```

### Building for Production

```bash
# Build for web
flutter build web

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Troubleshooting

### WebSocket Connection Issues
- Ensure backend is running and accessible
- Check if WebSocket endpoint is correct in `api_constants.dart`
- Verify JWT token is being sent in headers

### Login Issues
- Clear app data/cache
- Check backend logs for errors
- Verify API base URL is correct

## Future Enhancements

- [ ] Image/file sharing
- [ ] Voice messages
- [ ] Video/voice calls
- [ ] Message reactions
- [ ] Message forwarding
- [ ] Group management
- [ ] User search
- [ ] Push notifications
- [ ] Message encryption

## License

MIT License
