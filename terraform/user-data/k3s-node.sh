#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

# Enable swap (for t2.micro stability)
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Install dependencies
apt-get update -y
apt-get install -y curl git

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

# Set kubeconfig for this script
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Wait for cluster to be ready
until kubectl get nodes &>/dev/null; do sleep 2; done
until kubectl get pods -n kube-system | grep -q 'Running'; do sleep 2; done

# Create Kubernetes manifest with budget app + nginx+certbot sidecar
cat <<EOF | tee /root/budget-app.yaml
apiVersion: v1
kind: Service
metadata:
  name: budget-service
spec:
  selector:
    app: budget
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort

---
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
EOF

# Apply manifest
kubectl apply -f /root/budget-app.yaml
