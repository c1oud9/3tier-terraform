#!/bin/bash
# EKS 애플리케이션 배포 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     EKS 애플리케이션 배포 스크립트                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Terraform outputs 가져오기
echo -e "${YELLOW}[1/6]${NC} Terraform outputs 가져오기..."
EKS_CLUSTER_NAME=$(terraform output -raw aws_eks_cluster_name 2>/dev/null || echo "eks-prod")
RDS_ENDPOINT=$(terraform output -raw aws_rds_endpoint 2>/dev/null)
DB_USERNAME=$(terraform output -json db_credentials 2>/dev/null | jq -r '.username' || echo "admin")
DB_PASSWORD=$(terraform output -json db_credentials 2>/dev/null | jq -r '.password')

if [ -z "$RDS_ENDPOINT" ]; then
    echo -e "${RED}Error: RDS 엔드포인트를 가져올 수 없습니다.${NC}"
    echo "Terraform apply를 먼저 실행하세요."
    exit 1
fi

echo "  ✓ EKS 클러스터: $EKS_CLUSTER_NAME"
echo "  ✓ RDS 엔드포인트: $RDS_ENDPOINT"

# kubectl 설정
echo -e "\n${YELLOW}[2/6]${NC} kubectl 설정 중..."
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region ap-northeast-2

# AWS Load Balancer Controller 설치
echo -e "\n${YELLOW}[3/6]${NC} AWS Load Balancer Controller 설치 중..."

# Helm 설치 확인
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: Helm이 설치되어 있지 않습니다.${NC}"
    echo "설치 방법: https://helm.sh/docs/intro/install/"
    exit 1
fi

# EKS Charts 저장소 추가
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# ServiceAccount에 IAM Role 연결
LOAD_BALANCER_ROLE_ARN=$(terraform output -raw load_balancer_controller_role_arn 2>/dev/null)

# AWS Load Balancer Controller 설치
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="$EKS_CLUSTER_NAME" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LOAD_BALANCER_ROLE_ARN"

echo "  ✓ AWS Load Balancer Controller 설치 완료"

# ConfigMap 업데이트
echo -e "\n${YELLOW}[4/6]${NC} ConfigMap 업데이트 중..."
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: petclinic-config
  namespace: petclinic
data:
  SPRING_PROFILES_ACTIVE: "mysql"
  SPRING_DATASOURCE_URL: "jdbc:mysql://${RDS_ENDPOINT}/petclinic"
EOF

echo "  ✓ ConfigMap 생성 완료"

# Secret 생성
echo -e "\n${YELLOW}[5/6]${NC} Secret 생성 중..."
kubectl create secret generic petclinic-secret \
    --from-literal=SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
    --from-literal=SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
    --namespace=petclinic \
    --dry-run=client -o yaml | kubectl apply -f -

echo "  ✓ Secret 생성 완료"

# 애플리케이션 배포
echo -e "\n${YELLOW}[6/6]${NC} 애플리케이션 배포 중..."
kubectl apply -f k8s-manifests/application.yaml

echo -e "\n${GREEN}✓ 배포 완료!${NC}"

# 배포 상태 확인
echo -e "\n${YELLOW}배포 상태 확인 중...${NC}"
echo ""
kubectl get pods -n petclinic
echo ""
kubectl get svc -n petclinic

# Load Balancer 주소 가져오기
echo -e "\n${YELLOW}Load Balancer 주소 확인 중 (최대 3분 소요)...${NC}"
for i in {1..36}; do
    LB_HOSTNAME=$(kubectl get svc petclinic-web-service -n petclinic -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$LB_HOSTNAME" ]; then
        echo -e "\n${GREEN}✓ 애플리케이션 접속 주소:${NC}"
        echo -e "  ${GREEN}http://$LB_HOSTNAME${NC}"
        break
    fi
    echo -n "."
    sleep 5
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              배포가 완료되었습니다!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "다음 명령어로 상태를 확인할 수 있습니다:"
echo "  kubectl get all -n petclinic"
echo "  kubectl logs -f deployment/petclinic-was -n petclinic"
echo ""
