#!/bin/bash
set -e

echo "Deploying autoscalers (Metrics Server, Cluster Autoscaler, KEDA) to EKS cluster..."

CLUSTER_NAME="cloudmart-eks-prod"
REGION="ap-south-1"

# 1. Metrics Server
echo "Installing Metrics Server..."
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls}

# 2. Cluster Autoscaler
echo "Installing Cluster Autoscaler..."
helm repo add autoscaler https://kubernetes.github.io/autoscaler
# Get the AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/cloudmart-cluster-autoscaler-role-prod"

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set "autoDiscovery.clusterName=${CLUSTER_NAME}" \
  --set "awsRegion=${REGION}" \
  --set "rbac.serviceAccount.create=true" \
  --set "rbac.serviceAccount.name=cluster-autoscaler" \
  --set "rbac.serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${ROLE_ARN}"

# 3. KEDA
echo "Installing KEDA..."
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace

echo "Autoscaler deployment complete!"
