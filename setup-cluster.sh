#!/bin/bash
set -e

echo "🚀 Starting Chat App Kubernetes Setup..."

# 0. Check Prerequisites
if ! command -v kind &> /dev/null; then
    echo "❌ KIND is not installed. Installing via Homebrew..."
    brew install kind
else
    echo "✅ KIND is already installed."
fi

# 1. Create KIND Cluster
# KIND clusters run as Docker containers, so they automatically show up in Docker Desktop.
if kind get clusters | grep -q "chat-cluster"; then
    echo "✅ Cluster 'chat-cluster' already exists."
else
    echo "📦 Creating KIND cluster..."
    kind create cluster --name chat-cluster --config kind-config.yaml
fi

# 2. Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress resources to be created..."
sleep 20

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# 2.5 Install Metrics Server
if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
  echo "📊 Installing Metrics Server..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

  echo "🔧 Patching Metrics Server for Kind (Insecure TLS)..."
  kubectl patch -n kube-system deployment metrics-server --type=json \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
else
  echo "✅ Metrics Server is already installed."
fi

# 3. Create Namespace
echo "📂 Creating namespace 'chat-app'..."
kubectl apply -f k8s/namespace.yaml

# 4. Inject Environment Variables into ConfigMap and Secret
echo "🔑 Injecting environment variables..."

if [ ! -f .env ]; then
    echo "❌ .env file not found! Please create one."
    exit 1
fi

# Load .env vars
export $(grep -v '^#' .env | xargs)

# Base64 encode secrets for the secret.yaml template
export DB_USER_B64=$(echo -n "$DB_USER" | base64)
export DB_PASS_B64=$(echo -n "$DB_PASS" | base64)
export MONGO_USER_B64=$(echo -n "$MONGO_USER" | base64)
export MONGO_PASSWORD_B64=$(echo -n "$MONGO_PASSWORD" | base64)
export JWT_SECRET_B64=$(echo -n "$JWT_SECRET" | base64)

# Use envsubst to replace variables in the templates and apply them
# We use a temporary file to avoid overwriting the source templates if they were to be kept as templates
# But here we assume k8s/configmap.yaml and k8s/secret.yaml are the TEMPLATES.

# Apply ConfigMap
envsubst < k8s/configmap.yaml | kubectl apply -f -

# Apply Secret
envsubst < k8s/secret.yaml | kubectl apply -f -

echo "✅ ConfigMap and Secret applied."

# 5. Build Docker Images
echo "🔨 Building Docker images..."
# Build Frontend with BASE_URL=/backend
docker build -t chat-app-frontend:latest --build-arg BASE_URL=/backend ./chat-app-frontend
# Build Backend
docker build -t chat-app-backend:latest ./chat-app-backend

# 6. Load Images into KIND
echo "🚚 Loading images into KIND nodes..."
kind load docker-image chat-app-frontend:latest --name chat-cluster
kind load docker-image chat-app-backend:latest --name chat-cluster

# 7. Apply Manifests
echo "📄 Applying Kubernetes manifests..."
# ConfigMap and Secret are already applied.

kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/mongo.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml

# 8. Wait for Pods
echo "⏳ Waiting for all pods to be ready..."
kubectl wait --namespace chat-app \
  --for=condition=ready pod \
  --all \
  --timeout=300s

echo "🎉 Setup Complete!"
echo "------------------------------------------------"
echo "🌍 Access the app at: http://chat.abhishek.com"
echo "ℹ️  Ensure you have added '127.0.0.1 chat.abhishek.com' to your /etc/hosts file."
echo "------------------------------------------------"
echo "📊 Cluster Status:"
kubectl get pods -n chat-app
