# App Architecture

## Component Hierarchy

```
MyApp (Root)
│
└── AuthWrapper
    │
    ├── LoginScreen (if not authenticated)
    │   └── SignupScreen (navigation)
    │
    └── MainScreen (if authenticated)
        │
        ├── ChatListPanel (Left Side / Mobile View)
        │   ├── Header (Profile Avatar, Actions)
        │   ├── SearchBar
        │   └── RoomList
        │       └── RoomItem (Clickable)
        │
        ├── ChatPanel (Right Side / Mobile Navigation)
        │   ├── ChatHeader
        │   ├── MessagesList
        │   │   ├── DateHeader
        │   │   └── MessageBubble
        │   └── InputArea
        │       ├── EmojiButton
        │       ├── AttachButton
        │       ├── TextField
        │       └── SendButton
        │
        └── ProfileScreen (Overlay / Mobile Navigation)
            ├── ProfileHeader
            ├── ProfilePicture
            └── InfoSections
```

## Data Flow

```
User Action → UI Component → Service → Backend API
                                ↓
                            State Update
                                ↓
                            UI Re-render
```

### Example: Sending a Message

```
1. User types in TextField (chat_panel.dart)
   ↓
2. User presses Send button
   ↓
3. _handleSendMessage() called
   ↓
4. wsService.sendMessage() (websocket_service.dart)
   ↓
5. STOMP message sent to backend
   ↓
6. Backend broadcasts to /topic/room.{roomId}
   ↓
7. All subscribers receive ChatMessageResponse
   ↓
8. onMessage callback triggered
   ↓
9. setState() updates _messages list
   ↓
10. UI rebuilds with new message
```

## State Management

### Current Implementation
- **Local State**: Using `setState()` in StatefulWidgets
- **Shared State**: Passed via constructor parameters
- **Persistent State**: JWT token in SharedPreferences

### State Locations

| State | Location | Type |
|-------|----------|------|
| User Info | `MainScreen._currentUser` | Local |
| Room List | `MainScreen._rooms` | Local |
| Selected Room | `MainScreen._selectedRoom` | Local |
| Messages | `ChatPanel._messages` | Local |
| WebSocket Connection | `WebSocketService._isConnected` | Service |
| JWT Token | SharedPreferences | Persistent |

## Service Architecture

### ApiService (REST)
```
ApiService
├── setToken(token)
├── getToken()
├── clearToken()
├── signup()
├── login()
├── getCurrentUser()
├── getRooms()
├── createRoom()
└── getRoomMessages()
```

### WebSocketService (Real-time)
```
WebSocketService
├── connect()
├── disconnect()
├── subscribeToRoom(roomId, callback)
├── unsubscribeFromRoom(roomId)
└── sendMessage(roomId, content)
```

## Navigation Flow

```
App Start
    ↓
Check Token
    ↓
┌───────────────────────┐
│ Has Token?            │
├───────────────────────┤
│ YES          │   NO   │
↓              ↓        │
MainScreen   LoginScreen
│              │
│              └→ SignupScreen
│                    │
└←───────────────────┘
         │
         ↓
    MainScreen
         │
    ┌────┴────┐
    ↓         ↓
ChatPanel  ProfileScreen
```

## Responsive Layout Logic

```dart
final isLargeScreen = MediaQuery.of(context).size.width > 800;

if (isLargeScreen) {
    // Desktop: Side-by-side
    Row([
        ChatListPanel (400px),
        Expanded(ChatPanel or ProfileScreen)
    ])
} else {
    // Mobile: Stacked with navigation
    if (_selectedRoom == null && !_showProfile) {
        ChatListPanel (full width)
    } else if (_showProfile) {
        ProfileScreen (full width)
    } else {
        ChatPanel (full width)
    }
}
```

## WebSocket Connection Lifecycle

```
App Start
    ↓
Login Success
    ↓
wsService.connect()
    ↓
Connected
    ↓
Send addUser message
    ↓
Subscribe to user queue
    ↓
User opens chat
    ↓
subscribeToRoom(roomId)
    ↓
[Receive messages in real-time]
    ↓
User closes chat
    ↓
unsubscribeFromRoom(roomId)
    ↓
User logs out
    ↓
wsService.disconnect()
```

## Model Relationships

```
User (1) ←──────→ (N) Room
                    │
                    ↓
                 (N) Message
```

### User Model
```dart
User {
    int id
    String email
    String firstName
    String lastName
    DateTime createdAt
    String? about
    String? avatarUrl
}
```

### Room Model
```dart
Room {
    String id
    String name
    String description
    String type  // ONE_TO_ONE, GROUP
    List<int> participants
    int createdBy
    DateTime createdAt
    String? lastMessage
    DateTime? lastMessageTime
    int unreadCount
}
```

### Message Model
```dart
Message {
    String id
    String roomId
    int senderId
    String content
    String messageType  // TEXT, IMAGE, FILE
    DateTime createdAt
    bool edited
    bool isUserSelf
}
```

## API Response Structure

All API responses follow this format:

```json
{
    "success": true,
    "message": "Success message",
    "data": { ... }
}
```

### Pagination Response
```json
{
    "success": true,
    "message": "Messages retrieved",
    "data": {
        "content": [ ... ],
        "page": 0,
        "size": 20,
        "totalElements": 100,
        "totalPages": 5,
        "last": false
    }
}
```

## Error Handling

```
API Call
    ↓
Try Block
    ↓
Success? ──YES──→ Update State → UI Update
    │
    NO
    ↓
Catch Block
    ↓
Log Error
    ↓
Show SnackBar
    ↓
Return to Previous State
```

## Theme Structure

```
AppTheme
├── Colors
│   ├── primaryBackground (#111B21)
│   ├── secondaryBackground (#202C33)
│   ├── accentColor (#00A884)
│   ├── textPrimary (#E9EDEF)
│   ├── textSecondary (#8696A0)
│   └── ...
│
└── ThemeData
    ├── AppBarTheme
    ├── InputDecorationTheme
    ├── ElevatedButtonTheme
    ├── TextTheme
    └── ...
```

## File Organization Best Practices

```
lib/
├── config/          # App-wide configuration
├── models/          # Data models
├── screens/         # UI screens
│   ├── auth/       # Authentication screens
│   └── chat/       # Chat-related screens
├── services/        # Business logic & API
├── utils/           # Helper functions
└── main.dart        # Entry point
```

## Security Architecture

```
User Login
    ↓
Backend validates
    ↓
Returns JWT token
    ↓
Store in SharedPreferences
    ↓
Include in all API calls
    ↓
Backend validates token
    ↓
Return data or 401 Unauthorized
```

## Performance Considerations

### Message Loading
- Initial load: 20 messages
- Scroll pagination: Load more on demand
- Messages reversed for display (newest at bottom)

### WebSocket
- Single connection for entire app
- Multiple room subscriptions
- Auto-reconnect on disconnect (TODO)

### UI Rendering
- ListView.builder for efficient list rendering
- Conditional rendering based on screen size
- Image caching (when images implemented)

## Future Scalability

### Ready for:
- [ ] State management library (Provider, Riverpod, Bloc)
- [ ] Offline support (local database)
- [ ] Image/file upload
- [ ] Push notifications
- [ ] Multiple languages (i18n)
- [ ] Dark/Light mode toggle
- [ ] Message search
- [ ] Message encryption

### Architecture allows:
- Easy addition of new screens
- Simple API endpoint integration
- Flexible theme customization
- Platform-specific implementations
- Feature modules

---

**Last Updated**: 2025-11-16
