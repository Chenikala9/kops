#!/bin/bash

set -e  # Exit if any command fails

# === Configuration ===
BUCKET_NAME="prabhas.flm.k8s"
CLUSTER_NAME="govardhan.k8s.local"
KOPS_STATE_STORE="s3://${BUCKET_NAME}"
AWS_REGION="ap-south-1a"
MASTER_SIZE="t2.medium"
NODE_SIZE="t2.micro"
MASTER_COUNT=1
NODE_COUNT=2

echo "=== Exporting KOPS_STATE_STORE ==="
export KOPS_STATE_STORE=${KOPS_STATE_STORE}

echo "=== Updating PATH if needed ==="
grep -qxF 'export PATH=$PATH:/usr/local/bin/' ~/.bashrc || echo 'export PATH=$PATH:/usr/local/bin/' >> ~/.bashrc
source ~/.bashrc

echo "=== Installing/Updating AWS CLI ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
aws --version

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

echo "=== Installing kops ==="
KOPS_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -Lo kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/kops
kops version

echo "=== Creating S3 bucket: ${BUCKET_NAME} ==="
aws s3 mb s3://${BUCKET_NAME} || echo "Bucket may already exist"

echo "=== Creating Kubernetes cluster with Kops ==="
kops create cluster \
  --name=${CLUSTER_NAME} \
  --zones=${AWS_REGION} \
  --master-size=${MASTER_SIZE} \
  --node-size=${NODE_SIZE} \
  --master-count=${MASTER_COUNT} \
  --node-count=${NODE_COUNT} \
  --yes

echo "=== Waiting 60 seconds for cluster resources to start ==="
sleep 60

echo "=== Exporting kubeconfig ==="
kops export kubecfg --name ${CLUSTER_NAME}

echo "=== Verifying cluster nodes ==="
kubectl get nodes
