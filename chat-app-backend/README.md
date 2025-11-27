# Chat App Backend

A production-ready real-time chat application backend built with Spring Boot, Kotlin, WebSockets, and microservices architecture.

## 🚀 Features

- **Authentication & Authorization**: JWT-based secure authentication with Spring Security
- **Real-time Communication**: WebSocket-based messaging with STOMP protocol
- **Multi-database Architecture**: PostgreSQL for users, MongoDB for messages, Redis for caching/pub-sub
- **Scalability**: Redis pub/sub for horizontal scaling across multiple instances
- **Production Ready**: Docker containerization, health checks, metrics, and monitoring
- **API Documentation**: OpenAPI/Swagger integration
- **Testing**: Unit and integration tests with Testcontainers

## 🛠 Tech Stack

### Backend
- **Language**: Kotlin
- **Framework**: Spring Boot 3.x
- **Security**: Spring Security + JWT
- **WebSockets**: Spring WebSocket + STOMP
- **Databases**: PostgreSQL, MongoDB, Redis
- **Build Tool**: Maven
- **Containerization**: Docker + Docker Compose

### Architecture
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Client    │◄──►│   NGINX      │◄──►│   Backend   │
│ (React/JS)  │    │  (Reverse    │    │ (Spring)    │
└─────────────┘    │   Proxy)     │    └─────────────┘
                   └──────────────┘           │
                                              ▼
                   ┌──────────────────────────────────────┐
                   │          Data Layer                  │
                   ├──────────┬──────────┬────────────────┤
                   │PostgreSQL│ MongoDB  │     Redis      │
                   │ (Users)  │(Messages)│(Cache/PubSub)  │
                   └──────────┴──────────┴────────────────┘
```

## 🏃‍♂️ Quick Start

### Prerequisites
- Docker & Docker Compose
- JDK 21+ (for local development)
- Maven 3.6+ (for local development)

### 1. Start with Docker Compose (Recommended)
```bash
# Clone the repository
git clone <repository-url>
cd chat-app-backend

# Start all services
docker-compose up -d

# Check service health
docker-compose ps
```

The application will be available at:
- **API**: http://localhost/api
- **WebSocket**: ws://localhost/ws/chat
- **Swagger UI**: http://localhost/swagger-ui.html
- **Health Check**: http://localhost/actuator/health

### 2. Local Development Setup

#### Start Infrastructure Services
```bash
docker-compose up -d postgres mongo redis nginx
```

#### Run Backend Locally
```bash
# Build the application
./mvnw clean package

# Run with local profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

## 📡 API Endpoints

### Authentication
```
POST /api/auth/signup     # Register new user
POST /api/auth/login      # Login user
GET  /api/auth/me         # Get current user info
```

### Chat Rooms
```
POST /api/rooms           # Create new room
GET  /api/rooms           # Get user's rooms
GET  /api/rooms/{id}/messages  # Get room messages (paginated)
```

### WebSocket Endpoints
```
CONNECT /ws/chat          # WebSocket connection
/app/chat.sendMessage     # Send message
/app/chat.addUser         # User join notification
/topic/room.{roomId}      # Subscribe to room messages
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `local` |
| `DB_HOST` | PostgreSQL host | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_NAME` | Database name | `chatapp` |
| `DB_USER` | Database user | `chatuser` |
| `DB_PASS` | Database password | `chatpass` |
| `MONGO_HOST` | MongoDB host | `localhost` |
| `MONGO_PORT` | MongoDB port | `27017` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `JWT_SECRET` | JWT signing secret | `mySecretKey...` |
| `JWT_EXPIRATION` | JWT expiration (seconds) | `86400` |

### Profiles
- **local**: Local development with external databases
- **docker**: Docker environment
- **k8s**: Kubernetes deployment
- **test**: Testing with embedded/test databases

## 🧪 Testing

### Run Tests
```bash
# All tests
./mvnw test

# Specific test class
./mvnw test -Dtest=UserServiceIntegrationTest
```

### Integration Tests
Tests use Testcontainers for real database testing:
- PostgreSQL container for user repository tests
- MongoDB container for message repository tests
- Redis container for caching tests

## 🚢 Production Deployment

### Docker Build
```bash
# Build Docker image
docker build -t chat-app-backend .

# Run container
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=docker \
  chat-app-backend
```

### Kubernetes (Coming Soon)
Kubernetes manifests for production deployment:
- Deployment with multiple replicas
- Services and Ingress
- ConfigMaps and Secrets
- Horizontal Pod Autoscaler

## 📊 Monitoring & Observability

### Health Checks
- **Application**: `/actuator/health`
- **Database**: Connection pool health
- **Redis**: Connection health
- **Custom**: Business logic health checks

### Metrics
- **JVM Metrics**: Memory, GC, threads
- **Application Metrics**: Request rates, response times
- **Database Metrics**: Connection pools, query times
- **WebSocket Metrics**: Active connections, message rates

### Logging
- **Structured Logging**: JSON format for production
- **Log Levels**: Configurable per package
- **Correlation IDs**: Request tracing across services

## 🔒 Security Features

- **Password Hashing**: BCrypt with configurable strength
- **JWT Security**: RSA/HMAC signing with expiration
- **CORS Protection**: Configurable origins
- **Rate Limiting**: Protection against abuse
- **SQL Injection**: JPA parameterized queries
- **XSS Protection**: Input validation and sanitization

## 📝 Development Notes

### Database Schema
```sql
-- Users table (PostgreSQL)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    active BOOLEAN DEFAULT TRUE
);

-- MongoDB Collections
// rooms: { _id, name, type, participants[], createdBy, createdAt }
// messages: { _id, roomId, senderId, content, messageType, createdAt }
```

### WebSocket Message Flow
1. Client connects with JWT token
2. Authentication via JWT filter
3. Subscribe to room topics
4. Send/receive messages through STOMP
5. Redis pub/sub for multi-instance broadcasting

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Spring Boot team for the excellent framework
- Kotlin team for the amazing language
- WebSocket/STOMP for real-time capabilities
- Docker for containerization simplicity
