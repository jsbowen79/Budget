#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

# Enable swap for t2.micro stability
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Install dependencies
apt-get update -y
apt-get install -y curl git

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

# Export kubeconfig for this script
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Wait for cluster to be ready
until kubectl get nodes &>/dev/null; do sleep 2; done
until kubectl get pods -n kube-system | grep -q 'Running'; do sleep 2; done

# Apply Kubernetes manifest
cat <<EOF | tee /root/budget-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: budget
spec:
  replicas: 1
  selector:
    matchLabels:
      app: budget
  template:
    metadata:
      labels:
        app: budget
    spec:
      containers:
      - name: budget
        image: jsbowen79/budget:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: budget-service
spec:
  type: ClusterIP
  selector:
    app: budget
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
        listen 80;

        location / {
            proxy_pass http://budget-app-service:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config-volume
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config-volume
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080

EOF

# Apply the deployment
kubectl apply -f /root/budget-deployment.yaml

