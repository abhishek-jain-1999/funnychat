# 🗄 Database Access Guide

This guide explains how to connect to the internal **MongoDB** and **PostgreSQL** databases running in your Kubernetes cluster using local tools like **Studio 3T** and **pgAdmin**.

> [!NOTE]
> We use `kubectl port-forward` to securely access these services. This creates a tunnel from your local machine to the cluster without exposing ports to the public internet.

## 1. MongoDB Access

### Step 1: Start Port Forwarding
Run the following command in your terminal to forward the Mongo port (27017) to your local machine:

```bash
kubectl port-forward svc/mongo 27017:27017 -n chat-app
```
*Keep this terminal window open.*

### Step 2: Connect via Studio 3T
1.  Open **Studio 3T**.
2.  Click **Connect** -> **New Connection**.
3.  **Server** tab:
    *   **Name**: `Local K8s Mongo`
    *   **Address**: `localhost`
    *   **Port**: `27017`
4.  **Authentication** tab:
    *   **Authentication Mode**: `Basic (SCRAM-SHA-256)`
    *   **User Name**: (Check your `.env` file, default: `admin`)
    *   **Password**: (Check your `.env` file, default: `password`)
    *   **Authentication DB**: `admin` (usually) or `chatapp`
5.  Click **Test Connection** and then **Save**.

> [!TIP]
> If the connection fails, verify the port-forward is running and try using `127.0.0.1` instead of `localhost`.

---

## 2. PostgreSQL Access

### Step 1: Start Port Forwarding
Run the following command to forward the Postgres port (5432):

```bash
kubectl port-forward svc/postgres 5432:5432 -n chat-app
```
*Keep this terminal window open.*

### Step 2: Connect via pgAdmin
1.  Open **pgAdmin**.
2.  Right-click **Servers** -> **Register** -> **Server**.
3.  **General** tab:
    *   **Name**: `Local K8s Postgres`
4.  **Connection** tab:
    *   **Host name/address**: `localhost`
    *   **Port**: `5432`
    *   **Maintenance database**: `chatapp`
    *   **Username**: `chatuser` (or check `.env`)
    *   **Password**: (Check your `.env`)
5.  Click **Save**.

## Troubleshooting
*   **Port in use**: If you get an error that the port is in use, change the local port (left side):
    *   Example: `kubectl port-forward svc/mongo 27018:27017 -n chat-app` (Connect to localhost:27018).
*   **Connection refused**: Ensure the pod is running (`kubectl get pods -n chat-app`).
