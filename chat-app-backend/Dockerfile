# Build stage
FROM eclipse-temurin:21-jdk-jammy AS build

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY mvnw ./
COPY mvnw.cmd ./
COPY .mvn .mvn
COPY pom.xml ./

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN ./mvnw clean package -DskipTests

# Runtime stage (smaller)
FROM eclipse-temurin:21.0.1_12-jre-alpine

WORKDIR /app

# Install curl for healthcheck (Alpine uses apk)
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -S chatuser && adduser -S chatuser -G chatuser

# Copy the JAR file from build stage
COPY --from=build /app/target/chat-app-backend-*.jar app.jar

# Change ownership
RUN chown chatuser:chatuser app.jar

# Switch to non-root user
USER chatuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=300s --timeout=3s --start-period=5s --retries=3 \
#    CMD curl -fsS http://localhost:8080/actuator/health || exit 1
    CMD wget -qO- http://localhost:8080/actuator/health >/dev/null 2>&1 || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
