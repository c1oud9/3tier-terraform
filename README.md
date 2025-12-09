# 🌐 멀티클라우드 기반 고가용성 DR 아키텍처

> AWS와 Azure를 활용한 3-Tier 웹 서비스 및 Warm Standby 재해복구 아키텍처

## 📋 프로젝트 개요

이 프로젝트는 **AWS를 Primary Site**, **Azure를 DR Site**로 구성한 멀티클라우드 재해복구 아키텍처입니다. Terraform을 사용하여 Infrastructure as Code로 관리됩니다.

### 주요 특징

- ☁️ **AWS Primary Site**: ap-northeast-2 (서울)
  - 3-Tier 아키텍처 (Web/WAS/DB)
  - ECS Fargate 기반 컨테이너 오케스트레이션
  - RDS MySQL Multi-AZ 고가용성
  - External/Internal ALB를 통한 트래픽 분산

- 🔷 **Azure DR Site**: Korea Central
  - AKS (Azure Kubernetes Service) Warm Standby
  - Azure MySQL Flexible Server
  - Application Gateway
  - 최소 리소스 유지로 비용 최적화

- 🔒 **VPN 연결**: Site-to-Site IPsec VPN
  - AWS ↔ Azure 안전한 데이터 동기화
  - 5분 주기 자동 백업 및 복제

- 🌍 **DNS Failover**: Route 53 기반
  - Health Check 자동 모니터링
  - Primary 장애 시 자동 Failover

## 🏗️ 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                    🌐 Internet                               │
│                         │                                    │
│                    Route 53 DNS                              │
│                    (Failover)                                │
│              ┌──────────┴───────────┐                        │
└──────────────┼─────────────────────┼─────────────────────────┘
               │                     │
               ▼                     ▼ (Failover)
    ┌──────────────────┐    ┌──────────────────┐
    │  AWS Primary     │    │  Azure DR        │
    │  ap-northeast-2  │◄───┤  Korea Central   │
    └──────────────────┘    └──────────────────┘
           │                        │
           │                   VPN Tunnel
           │                        │
    ┌──────▼──────┐          ┌─────▼──────┐
    │ External ALB │          │ App Gateway │
    └──────┬──────┘          └─────┬──────┘
           │                        │
    ┌──────▼──────┐          ┌─────▼──────┐
    │  Web Tier   │          │ AKS Cluster │
    │   (Nginx)   │          │  (Standby)  │
    └──────┬──────┘          └─────┬──────┘
           │                        │
    ┌──────▼──────┐          ┌─────▼──────┐
    │ Internal ALB │          │            │
    └──────┬──────┘          │            │
           │                  │            │
    ┌──────▼──────┐          │            │
    │  WAS Tier   │          │            │
    │  (Tomcat)   │          │            │
    └──────┬──────┘          │            │
           │                  │            │
    ┌──────▼──────┐          ┌─────▼──────┐
    │ RDS MySQL   │─────────▶│Azure MySQL │
    │  Multi-AZ   │ Sync (5m)│  (Standby) │
    └─────────────┘          └────────────┘
```

## 📊 주요 메트릭

| 메트릭 | 목표값 | 설명 |
|--------|--------|------|
| **RTO** | ~10분 | 재해 발생 시 복구 소요 시간 |
| **RPO** | 5분 | 최대 데이터 손실 시간 |
| **가용성** | 99.95% | Multi-AZ + DR 구성 |
| **동기화 주기** | 5분 | Lambda를 통한 자동 백업 |

## 🚀 빠른 시작

### 사전 요구사항

```bash
# Terraform 설치 (v1.5.0+)
brew install terraform  # macOS
# 또는
sudo apt-get install terraform  # Ubuntu

# AWS CLI 설치 및 설정
aws configure

# Azure CLI 설치 및 로그인
az login
```

### 1️⃣ 저장소 클론

```bash
git clone <repository-url>
cd terraform-multi-cloud-dr
```

### 2️⃣ 변수 설정

`terraform.tfvars` 파일을 생성하고 필요한 값을 설정합니다:

```hcl
# terraform.tfvars
environment = "prod"
aws_region  = "ap-northeast-2"
azure_region = "koreacentral"

# 도메인 설정
domain_name = "your-domain.com"

# 데이터베이스 설정
db_name     = "petclinic"
db_username = "admin"

# 알림 이메일
alarm_email = "admin@example.com"
```

### 3️⃣ Lambda 함수 패키징

```bash
cd scripts/lambda-db-sync
./package.sh
cd ../..
```

### 4️⃣ Terraform 초기화 및 배포

```bash
# Terraform 초기화
terraform init

# 실행 계획 확인
terraform plan

# 인프라 배포
terraform apply
```

배포 완료 후 출력되는 정보를 확인하세요:

```
Outputs:

aws_external_alb_dns = "ext-alb-prod-1234567890.ap-northeast-2.elb.amazonaws.com"
aws_rds_endpoint = "rds-mysql-prod.abc123.ap-northeast-2.rds.amazonaws.com:3306"
azure_aks_cluster_name = "aks-dr-prod"
primary_endpoint = "http://your-domain.com"
...
```

## 📁 프로젝트 구조

```
terraform-multi-cloud-dr/
├── main.tf                 # 메인 Terraform 구성
├── variables.tf            # 입력 변수 정의
├── outputs.tf              # 출력 변수 정의
├── terraform.tfvars        # 변수 값 설정 (gitignore)
│
├── modules/
│   ├── vpc/               # AWS VPC 모듈
│   │   ├── aws_vpc.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── alb/               # Application Load Balancer 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── rds/               # RDS MySQL 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecs/               # ECS Fargate 모듈
│   ├── aks/               # Azure AKS 모듈
│   ├── mysql/             # Azure MySQL 모듈
│   └── vpn/               # VPN 연결 모듈
│
└── scripts/
    └── lambda-db-sync/    # DB 동기화 Lambda 함수
        ├── index.py
        ├── requirements.txt
        └── package.sh
```

## 🔧 주요 구성 요소

### AWS 리소스

| 리소스 | 설명 | 수량 |
|--------|------|------|
| VPC | 10.0.0.0/16 | 1 |
| Public Subnet | ALB, NAT Gateway | 2 (AZ-A, AZ-C) |
| Private Subnet | Web/WAS Tier | 4 (각 2개씩) |
| DB Subnet | RDS | 2 |
| External ALB | 인터넷 트래픽 수신 | 1 |
| Internal ALB | WAS 트래픽 분산 | 1 |
| RDS MySQL | Multi-AZ | 1 |
| Lambda | DB 동기화 (5분 주기) | 1 |
| S3 | 백업 저장소 | 1 |
| Route 53 | DNS Failover | 1 |

### Azure 리소스

| 리소스 | 설명 | 수량 |
|--------|------|------|
| VNet | 172.16.0.0/16 | 1 |
| AKS | Warm Standby (1 노드) | 1 |
| Azure MySQL | Flexible Server | 1 |
| App Gateway | 트래픽 라우팅 | 1 |
| VPN Gateway | Site-to-Site VPN | 1 |

## 🔐 보안 구성

### 네트워크 보안

- **보안 그룹**: 계층별 최소 권한 원칙
  - External ALB: 80, 443 포트만 인터넷에서 허용
  - Web Tier: ALB에서만 접근 허용
  - WAS Tier: Internal ALB에서만 접근 허용
  - DB Tier: WAS Tier와 Lambda에서만 접근 허용

- **Private Subnet**: 인터넷 직접 접근 차단
  - NAT Gateway를 통한 아웃바운드만 허용

### 데이터 보안

- **암호화**:
  - RDS: 저장 시 암호화 (AES-256)
  - S3: 서버 측 암호화
  - VPN: IPsec 터널 암호화

- **자격증명 관리**:
  - Random 패스워드 자동 생성
  - Terraform State에 민감 정보 보호

## 📈 모니터링 및 알람

### CloudWatch 대시보드

- **RDS 메트릭**:
  - CPU Utilization (임계값: 80%)
  - Database Connections (임계값: 150)
  - Free Storage Space (임계값: 10GB)

- **ALB 메트릭**:
  - Target Response Time
  - Request Count
  - Healthy/Unhealthy Host Count

### Health Check

- **Route 53 Health Check**:
  - 30초 간격 HTTP 체크
  - 3회 연속 실패 시 Failover
  - 엔드포인트: `/health`

## 💰 비용 최적화

### Warm Standby 전략

- Azure AKS: 최소 노드 수 (1개) 유지
- Azure MySQL: 최소 SKU (B_Standard_B1ms)
- Auto Scaling: 장애 시에만 스케일 아웃

### 예상 월 비용

| 항목 | 월 비용 (USD) |
|------|---------------|
| AWS Primary | ~$300-500 |
| Azure DR | ~$150-250 |
| **총계** | **~$450-750** |

## 🔄 재해복구 절차

### 자동 Failover

1. Route 53 Health Check가 Primary 장애 감지
2. DNS가 자동으로 Azure로 트래픽 라우팅
3. Azure AKS Auto Scaling 트리거
4. Azure MySQL Read-Only → Read-Write 전환

### 수동 복구

```bash
# Azure AKS 스케일 아웃
az aks scale --resource-group rg-dr-prod \
  --name aks-dr-prod \
  --node-count 3

# MySQL 쓰기 모드 활성화
az mysql flexible-server update \
  --resource-group rg-dr-prod \
  --name mysql-dr-prod \
  --high-availability Enabled
```

## 🧪 테스트

### Health Check 테스트

```bash
# Primary Site Health Check
curl -I http://your-domain.com/actuator/health

# Azure DR Site 직접 테스트
curl -I http://<azure-app-gateway-ip>/actuator/health
```

### Failover 테스트

```bash
# Route 53 Health Check 강제 실패 시뮬레이션
# (AWS Console에서 수동으로 Health Check 비활성화)

# DNS 전파 확인
dig your-domain.com
```

## 📚 추가 리소스

### Terraform 명령어

```bash
# 특정 리소스만 적용
terraform apply -target=module.aws_rds

# 리소스 삭제
terraform destroy

# 상태 확인
terraform show

# 출력 값만 보기
terraform output
```

### 유용한 AWS CLI 명령어

```bash
# RDS 상태 확인
aws rds describe-db-instances \
  --db-instance-identifier rds-mysql-prod

# Lambda 로그 확인
aws logs tail /aws/lambda/db-sync-prod --follow

# S3 백업 파일 확인
aws s3 ls s3://db-backup-prod-<account-id>/backups/
```

### Azure CLI 명령어

```bash
# AKS 자격증명 가져오기
az aks get-credentials \
  --resource-group rg-dr-prod \
  --name aks-dr-prod

# AKS 노드 확인
kubectl get nodes

# MySQL 상태 확인
az mysql flexible-server show \
  --resource-group rg-dr-prod \
  --name mysql-dr-prod
```

## 🐛 트러블슈팅

### Lambda 함수가 RDS에 연결하지 못하는 경우

```bash
# Security Group 확인
aws ec2 describe-security-groups \
  --group-ids <rds-sg-id>

# Lambda VPC 설정 확인
aws lambda get-function-configuration \
  --function-name db-sync-prod
```

### VPN 연결이 안 되는 경우

```bash
# AWS VPN 상태 확인
aws ec2 describe-vpn-connections

# Azure VPN 상태 확인
az network vpn-connection show \
  --resource-group rg-dr-prod \
  --name aws-to-azure-vpn
```

## 🤝 기여

이 프로젝트는 AWS2 팀 최종 프로젝트의 일환으로 개발되었습니다.

## 📝 라이선스

이 프로젝트는 교육 목적으로 작성되었습니다.

## ⚠️ 주의사항

- **비용**: 리소스를 사용하지 않을 때는 `terraform destroy`로 삭제하세요
- **보안**: 프로덕션 환경에서는 반드시 SSL/TLS 인증서를 구성하세요
- **백업**: Terraform State 파일을 안전하게 백업하세요
- **테스트**: 프로덕션 배포 전 반드시 Dev/Staging 환경에서 테스트하세요

---

**Made with ❤️ for AWS2 Final Project**
