#!/bin/bash
set -e

echo "=========================================="
echo "AWS Load Balancer Controller 설치"
echo "=========================================="

# IAM Policy 다운로드
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

# IAM Policy 생성
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json \
    --region ap-northeast-2 2>/dev/null || echo "Policy already exists"

# OIDC Provider 연결
eksctl utils associate-iam-oidc-provider \
  --cluster prod-eks \
  --region ap-northeast-2 \
  --approve

# Service Account 생성
eksctl create iamserviceaccount \
  --cluster=prod-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region=ap-northeast-2 \
  --approve

# Helm 설치
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# VPC ID 가져오기
VPC_ID=$(cd .. && terraform output -raw vpc_id)

# Controller 설치
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=prod-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-northeast-2 \
  --set vpcId=$VPC_ID

echo ""
echo "Controller 설치 완료!"
echo "Pod 상태 확인:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

rm -f iam-policy.json
