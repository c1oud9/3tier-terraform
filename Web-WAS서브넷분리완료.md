# ✅ Web/WAS 서브넷 분리 완료!

## 🔄 주요 변경 사항

### AS-IS (이전)
```
Private Subnet에 모든 EKS 노드 배치
├─ EKS Node (혼합)
   ├─ Web Pod
   └─ WAS Pod
```

### TO-BE (현재)
```
Web Subnet (10.0.11.0/24, 10.0.12.0/24)
├─ EKS Web Node (tier=web)
   └─ Web Pod (nginx) - nodeSelector: tier=web

WAS Subnet (10.0.21.0/24, 10.0.22.0/24)
├─ EKS WAS Node (tier=was)
   └─ WAS Pod (spring-boot) - nodeSelector: tier=was
```

---

## 🏗️ 새로운 아키텍처

### Availability Zone A
```
┌─────────────────────────────────────────┐
│  Web Subnet 10.0.11.0/24               │
│  ├─ EKS Web Node (t3.medium)           │
│  │  └─ Web Pod (Nginx)                 │
├─────────────────────────────────────────┤
│  WAS Subnet 10.0.21.0/24               │
│  ├─ EKS WAS Node (t3.medium)           │
│  │  └─ WAS Pod (Spring Boot)           │
├─────────────────────────────────────────┤
│  DB Subnet 10.0.31.0/24                │
│  └─ RDS MySQL Primary                  │
└─────────────────────────────────────────┘
```

### Availability Zone C
```
┌─────────────────────────────────────────┐
│  Web Subnet 10.0.12.0/24               │
│  ├─ EKS Web Node (t3.medium)           │
│  │  └─ Web Pod (Nginx)                 │
├─────────────────────────────────────────┤
│  WAS Subnet 10.0.22.0/24               │
│  ├─ EKS WAS Node (t3.medium)           │
│  │  └─ WAS Pod (Spring Boot)           │
├─────────────────────────────────────────┤
│  DB Subnet 10.0.32.0/24                │
│  └─ RDS MySQL Standby                  │
└─────────────────────────────────────────┘
```

---

## 📝 수정된 파일 목록

### 1. Terraform 파일

#### modules/eks/main.tf
```terraform
# 기존: 단일 Node Group
resource "aws_eks_node_group" "main" { ... }

# 변경: Web/WAS 별도 Node Group
resource "aws_eks_node_group" "web" {
  subnet_ids = var.web_subnets
  labels = { tier = "web" }
}

resource "aws_eks_node_group" "was" {
  subnet_ids = var.was_subnets
  labels = { tier = "was" }
}
```

#### modules/eks/variables.tf
```terraform
# 추가된 변수
variable "web_subnets" { ... }      # Web Tier 서브넷
variable "was_subnets" { ... }      # WAS Tier 서브넷

variable "web_desired_size" { ... }  # Web 노드 수
variable "was_desired_size" { ... }  # WAS 노드 수
```

#### main.tf
```terraform
module "aws_eks" {
  web_subnets = module.aws_vpc.web_subnets
  was_subnets = module.aws_vpc.was_subnets
  
  web_desired_size = var.eks_web_desired_size
  was_desired_size = var.eks_was_desired_size
}
```

### 2. Kubernetes 매니페스트

#### k8s-manifests/application.yaml
```yaml
# Web Deployment
spec:
  template:
    spec:
      nodeSelector:
        tier: web    # Web 노드에만 배치

# WAS Deployment
spec:
  template:
    spec:
      nodeSelector:
        tier: was    # WAS 노드에만 배치
```

### 3. 변수 파일

#### variables.tf
```terraform
# Web Tier
variable "eks_web_desired_size" { default = 2 }
variable "eks_web_min_size" { default = 1 }
variable "eks_web_max_size" { default = 4 }

# WAS Tier
variable "eks_was_desired_size" { default = 2 }
variable "eks_was_min_size" { default = 1 }
variable "eks_was_max_size" { default = 4 }
```

#### terraform.tfvars.example
```hcl
# Web Tier Node Group (Web Subnet에 배치)
eks_web_desired_size   = 2
eks_web_min_size       = 1
eks_web_max_size       = 4

# WAS Tier Node Group (WAS Subnet에 배치)
eks_was_desired_size   = 2
eks_was_min_size       = 1
eks_was_max_size       = 4
```

### 4. 아키텍처 다이어그램

#### arch.mermaid
```mermaid
AZ-A
├─ Web Subnet 10.0.11.0/24
│  └─ EKS Web Node (tier=web)
├─ WAS Subnet 10.0.21.0/24
│  └─ EKS WAS Node (tier=was)
└─ DB Subnet 10.0.31.0/24
   └─ RDS Primary
```

---

## 🎯 서브넷 분리의 장점

### 1. 보안 강화
- **네트워크 격리**: Web과 WAS가 다른 서브넷에 위치
- **세밀한 Security Group**: 계층별 접근 제어
- **Network ACL**: 서브넷 레벨 방화벽

### 2. 장애 격리
- **영향 범위 최소화**: Web 장애가 WAS에 직접 영향 안 줌
- **독립적 스케일링**: Web/WAS 각각 Auto Scaling
- **디버깅 용이**: 계층별 트래픽 분석

### 3. 관리 용이성
- **명확한 책임 분리**: 계층별 관리자 지정 가능
- **리소스 추적**: 서브넷별 비용 및 사용량 추적
- **정책 적용**: 계층별 다른 정책 적용

### 4. 확장성
- **선택적 확장**: Web만 또는 WAS만 확장 가능
- **리소스 최적화**: 계층별 다른 인스턴스 타입 사용 가능
- **로드 분산**: 계층별 독립적인 로드 밸런싱

---

## 📊 서브넷 구성

### Public Subnets (인터넷 게이트웨이)
| Subnet | CIDR | AZ | 용도 |
|--------|------|----|------|
| public-a | 10.0.1.0/24 | AZ-A | ALB, NAT Gateway |
| public-c | 10.0.2.0/24 | AZ-C | ALB |

### Web Tier Subnets (Private)
| Subnet | CIDR | AZ | 리소스 |
|--------|------|----|--------|
| web-a | 10.0.11.0/24 | AZ-A | EKS Web Node, Web Pod |
| web-c | 10.0.12.0/24 | AZ-C | EKS Web Node, Web Pod |

### WAS Tier Subnets (Private)
| Subnet | CIDR | AZ | 리소스 |
|--------|------|----|--------|
| was-a | 10.0.21.0/24 | AZ-A | EKS WAS Node, WAS Pod |
| was-c | 10.0.22.0/24 | AZ-C | EKS WAS Node, WAS Pod |

### DB Tier Subnets (Private)
| Subnet | CIDR | AZ | 리소스 |
|--------|------|----|--------|
| db-a | 10.0.31.0/24 | AZ-A | RDS Primary |
| db-c | 10.0.32.0/24 | AZ-C | RDS Standby |

---

## 🔐 Security Group 구성

### 1. External ALB SG
```
Ingress: 0.0.0.0/0:80, 443
Egress:  Web Subnet (10.0.11.0/24, 10.0.12.0/24)
```

### 2. Web Node SG
```
Ingress: External ALB SG
Egress:  WAS Subnet (10.0.21.0/24, 10.0.22.0/24)
```

### 3. WAS Node SG
```
Ingress: Web Node SG
Egress:  DB Subnet (10.0.31.0/24, 10.0.32.0/24)
```

### 4. RDS SG
```
Ingress: WAS Node SG:3306
Egress:  -
```

---

## 🚀 배포 방법

### 1단계: Terraform 변수 설정
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Web/WAS 노드 수 설정
eks_web_desired_size = 2
eks_was_desired_size = 2
```

### 2단계: Terraform 배포
```bash
terraform init
terraform plan
terraform apply
```

### 3단계: 노드 그룹 확인
```bash
# EKS 클러스터 접속
aws eks update-kubeconfig --name eks-prod

# 노드 확인
kubectl get nodes --show-labels

# 결과 예시:
# NAME                          STATUS   LABELS
# ip-10-0-11-123.ec2.internal   Ready    tier=web,role=frontend
# ip-10-0-21-456.ec2.internal   Ready    tier=was,role=backend
```

### 4단계: Pod 배치 확인
```bash
kubectl get pods -n petclinic -o wide

# Web Pod는 Web Subnet (10.0.11.x, 10.0.12.x) 노드에 배치
# WAS Pod는 WAS Subnet (10.0.21.x, 10.0.22.x) 노드에 배치
```

---

## 🧪 테스트

### 1. nodeSelector 동작 확인
```bash
# Web Pod가 Web 노드에만 스케줄되는지 확인
kubectl describe pod <web-pod-name> -n petclinic | grep Node:

# WAS Pod가 WAS 노드에만 스케줄되는지 확인
kubectl describe pod <was-pod-name> -n petclinic | grep Node:
```

### 2. 네트워크 연결 확인
```bash
# Web Pod에서 WAS Pod로 연결 확인
kubectl exec -it <web-pod-name> -n petclinic -- curl http://petclinic-was-service:8080/actuator/health

# WAS Pod에서 RDS 연결 확인
kubectl exec -it <was-pod-name> -n petclinic -- nc -zv <rds-endpoint> 3306
```

### 3. 서브넷 확인
```bash
# Web 노드의 서브넷 확인
aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=eks-web-nodes-prod" \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress,SubnetId]'

# WAS 노드의 서브넷 확인
aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=eks-was-nodes-prod" \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress,SubnetId]'
```

---

## 💡 추가 최적화 방안

### 1. 인스턴스 타입 차별화
```hcl
# Web Tier: 낮은 사양
resource "aws_eks_node_group" "web" {
  instance_types = ["t3.small"]   # 2 vCPU, 2GB RAM
}

# WAS Tier: 높은 사양
resource "aws_eks_node_group" "was" {
  instance_types = ["t3.large"]   # 2 vCPU, 8GB RAM
}
```

### 2. Spot Instances 활용
```hcl
# Web Tier는 Spot Instance로 비용 절감
resource "aws_eks_node_group" "web" {
  capacity_type = "SPOT"
}

# WAS Tier는 On-Demand로 안정성 확보
resource "aws_eks_node_group" "was" {
  capacity_type = "ON_DEMAND"
}
```

### 3. Taint/Toleration 추가
```yaml
# Web Node에 Taint 설정
nodeSelector:
  tier: web
tolerations:
- key: "tier"
  operator: "Equal"
  value: "web"
  effect: "NoSchedule"
```

---

## 📚 참고 자료

- **Kubernetes Node Selector**: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector
- **EKS Node Groups**: https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
- **VPC Subnetting**: https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html

---

## ✅ 완료 체크리스트

- [x] Web Tier 전용 Node Group 생성
- [x] WAS Tier 전용 Node Group 생성
- [x] Web Subnet 배치 (10.0.11.0/24, 10.0.12.0/24)
- [x] WAS Subnet 배치 (10.0.21.0/24, 10.0.22.0/24)
- [x] Kubernetes nodeSelector 설정
- [x] Node Group Labels 설정
- [x] 변수 파일 업데이트
- [x] 아키텍처 다이어그램 수정
- [x] Security Group 계층 분리
- [x] 문서 업데이트

---

**이제 Web과 WAS가 완전히 분리된 서브넷에 배치됩니다!** 🎉

더 강력한 보안과 관리 용이성을 제공합니다.
