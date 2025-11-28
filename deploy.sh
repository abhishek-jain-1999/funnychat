#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

SERVICE=$1

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <backend|frontend|backend-media>"
  exit 1
fi

# Handle legacy name
if [ "$SERVICE" == "backend-media" ]; then
  echo "ℹ️  'backend-media' target has been renamed to 'backend-media'. Using new name..."
  SERVICE="backend-media"
fi

if [ "$SERVICE" == "backend" ]; then
  echo "🚀 Deploying Backend..."
  
  echo "📦 Building Docker image..."
  docker build -t chat-app-backend:latest ./chat-app-backend
  
  echo "🔄 Loading image into Kind..."
  kind load docker-image chat-app-backend:latest --name chat-cluster
  
  echo "⚙️  Applying Kubernetes configuration..."
  kubectl apply -f k8s/backend.yaml
  
  echo "♻️  Restarting deployment..."
  kubectl rollout restart deployment/backend -n chat-app
  
  echo "✅ Backend deployment completed!"

elif [ "$SERVICE" == "frontend" ]; then
  echo "🚀 Deploying Frontend..."
  
  echo "📦 Building Docker image..."
  # Using default BASE_URL=/backend as per Dockerfile, but specifying it explicitly for clarity
  docker build --build-arg BASE_URL=/backend -t chat-app-frontend:latest ./chat-app-frontend
  
  echo "🔄 Loading image into Kind..."
  kind load docker-image chat-app-frontend:latest --name chat-cluster
  
  echo "⚙️  Applying Kubernetes configuration..."
  kubectl apply -f k8s/frontend.yaml
  
  echo "♻️  Restarting deployment..."
  kubectl rollout restart deployment/frontend -n chat-app
  
  echo "✅ Frontend deployment completed!"

elif [ "$SERVICE" == "backend-media" ]; then
  echo "🚀 Deploying Media Service..."
  
  echo "📦 Building Docker image..."
  docker build -t chat-app-backend-media:latest ./chat-app-backend-media
  
  echo "🔄 Loading image into Kind..."
  kind load docker-image chat-app-backend-media:latest --name chat-cluster
  
  echo "⚙️  Applying Kubernetes configuration..."
  kubectl apply -f k8s/media-service.yaml
  
  echo "♻️  Restarting deployment..."
  kubectl rollout restart deployment/backend-media -n chat-app
  
  echo "✅ Media Service deployment completed!"

else
  echo "❌ Invalid service: $SERVICE. Use 'backend', 'frontend', or 'backend-media'."
  exit 1
fi