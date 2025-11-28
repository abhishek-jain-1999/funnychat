# Build stage
FROM eclipse-temurin:21-jdk-jammy AS build

WORKDIR /app

# Copy the wrapper scripts and config FIRST
COPY mvnw .
COPY .mvn .mvn
# Copy pom.xml
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

RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -S chatuser && adduser -S chatuser -G chatuser

# Copy the JAR file from build stage
COPY --from=build /app/target/chat-app-backend-media-*.jar app.jar

# Change ownership
RUN chown chatuser:chatuser app.jar

# Switch to non-root user
USER chatuser

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=300s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8081/actuator/health >/dev/null 2>&1 || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
