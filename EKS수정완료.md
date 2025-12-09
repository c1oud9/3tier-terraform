# ✅ EKS 버전으로 수정 완료!

## 🔄 주요 변경 사항

### AS-IS (이전 - ECS)
- **컨테이너 오케스트레이션**: ECS Fargate
- **Web Tier**: ECS Task (Nginx)
- **WAS Tier**: ECS Task (Spring Boot)
- **관리 방식**: AWS 관리형 서비스

### TO-BE (현재 - EKS)
- **컨테이너 오케스트레이션**: EKS (Elastic Kubernetes Service)
- **Web Tier**: Kubernetes Pod (Nginx) - Replica: 2
- **WAS Tier**: Kubernetes Pod (Spring Boot) - Replica: 2
- **관리 방식**: Kubernetes 네이티브

---

## 📦 수정된 파일 목록

### 1. 새로 추가된 파일
```
✅ modules/eks/
   ├── main.tf              # EKS 클러스터 및 노드 그룹
   ├── variables.tf
   └── outputs.tf

✅ k8s-manifests/
   └── application.yaml     # Kubernetes 배포 매니페스트 (Full Stack)

✅ scripts/
   └── deploy-eks-app.sh   # EKS 애플리케이션 자동 배포 스크립트
```

### 2. 삭제된 파일
```
❌ modules/ecs/            # ECS 모듈 전체 삭제
```

### 3. 수정된 파일
```
📝 main.tf                 # ECS → EKS 모듈 호출로 변경
📝 variables.tf            # ECS 변수 → EKS 변수로 변경
📝 terraform.tfvars.example # ECS 설정 → EKS 설정으로 변경
```

---

## 🏗️ 새로운 아키텍처

### AWS Primary Site (EKS 기반)
```
Internet
    ↓
Route 53 (DNS Failover)
    ↓
ALB (AWS Load Balancer Controller)
    ↓
┌─────────────────────────────────────┐
│     EKS Cluster (ap-northeast-2)    │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Web Tier (Nginx Pods)        │ │
│  │  - Replica: 2                 │ │
│  │  - HPA: CPU 70%               │ │
│  └──────────┬────────────────────┘ │
│             ↓                       │
│  ┌───────────────────────────────┐ │
│  │  WAS Tier (Spring Boot Pods)  │ │
│  │  - Replica: 2                 │ │
│  │  - HPA: CPU 70%, Memory 80%   │ │
│  └──────────┬────────────────────┘ │
└─────────────┼───────────────────────┘
              ↓
    RDS MySQL (Multi-AZ)
```

---

## 🆕 EKS의 주요 기능

### 1. Kubernetes 네이티브
- **Deployments**: 선언적 배포 관리
- **Services**: 내부 로드 밸런싱
- **HPA**: Horizontal Pod Autoscaler (자동 스케일링)
- **ConfigMap & Secret**: 설정 및 비밀 관리

### 2. AWS Load Balancer Controller
- ALB와 EKS 자동 연동
- Service 타입 LoadBalancer 지원
- Health Check 자동 설정

### 3. Auto Scaling
```yaml
# WAS Tier HPA
minReplicas: 2
maxReplicas: 10
CPU: 70%
Memory: 80%

# Web Tier HPA
minReplicas: 2
maxReplicas: 6
CPU: 70%
```

### 4. IRSA (IAM Roles for Service Accounts)
- Kubernetes ServiceAccount에 IAM Role 연결
- AWS 리소스 안전한 접근

### 5. EBS CSI Driver
- 영구 볼륨 지원
- StatefulSet 활용 가능

---

## 🚀 배포 방법

### 1단계: Terraform으로 인프라 배포
```bash
cd terraform-multi-cloud-dr

# 변수 설정
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Lambda 패키징
cd scripts/lambda-db-sync && ./package.sh && cd ../..

# Terraform 배포
terraform init
terraform plan
terraform apply
```

### 2단계: EKS 클러스터 접속
```bash
# kubectl 설정
aws eks update-kubeconfig --name eks-prod --region ap-northeast-2

# 노드 확인
kubectl get nodes
```

### 3단계: 애플리케이션 배포
```bash
# 자동 배포 스크립트 실행 (권장)
./scripts/deploy-eks-app.sh

# 또는 수동 배포
kubectl apply -f k8s-manifests/application.yaml
```

### 4단계: 배포 확인
```bash
# Pod 상태 확인
kubectl get pods -n petclinic

# Service 확인
kubectl get svc -n petclinic

# Load Balancer 주소 확인
kubectl get svc petclinic-web-service -n petclinic

# 로그 확인
kubectl logs -f deployment/petclinic-was -n petclinic
```

---

## 📊 EKS vs ECS 비교

| 항목 | ECS Fargate | EKS |
|------|-------------|-----|
| **학습 곡선** | 낮음 (AWS 네이티브) | 높음 (Kubernetes) |
| **유연성** | 중간 | 매우 높음 |
| **멀티클라우드** | AWS 전용 | 이식 가능 |
| **비용** | Task 기반 | 노드 기반 + $0.10/시간 (클러스터) |
| **Auto Scaling** | 서비스 레벨 | Pod + 노드 레벨 |
| **생태계** | AWS 서비스 | Kubernetes 생태계 |
| **관리 복잡도** | 낮음 | 중간-높음 |

---

## 💰 예상 비용 변경

### ECS (이전)
- Fargate vCPU/Memory 시간당 과금
- Web: 0.25vCPU, 512MB × 2 = ~$20/월
- WAS: 0.5vCPU, 1GB × 2 = ~$40/월
- **Total: ~$60/월**

### EKS (현재)
- EKS 클러스터: $0.10/시간 = ~$73/월
- EC2 t3.medium × 2: ~$60/월
- **Total: ~$133/월**

**차이: +$73/월** (하지만 더 강력한 기능과 유연성)

---

## 🎯 EKS의 장점

### 1. Kubernetes 표준
- **산업 표준**: 가장 널리 사용되는 컨테이너 오케스트레이션
- **이식성**: AWS → Azure/GCP 이전 용이
- **생태계**: Helm, Prometheus, Istio 등 풍부한 도구

### 2. 세밀한 제어
- **Pod 레벨 관리**: 더 세밀한 리소스 제어
- **Custom Scheduling**: Node Affinity, Taints/Tolerations
- **네트워크 정책**: Pod 간 통신 제어

### 3. 멀티 테넌시
- **Namespace**: 논리적 분리
- **RBAC**: 역할 기반 접근 제어
- **Resource Quotas**: 리소스 제한

### 4. DR 전략 일관성
- **AWS EKS ↔ Azure AKS**: 동일한 Kubernetes 사용
- **매니페스트 재사용**: 거의 동일한 YAML 파일
- **운영 일관성**: kubectl 명령어 동일

---

## 📚 주요 Kubernetes 리소스

### 생성된 리소스 목록
```bash
kubectl get all -n petclinic
```

```
NAME                                 READY   STATUS    RESTARTS   AGE
pod/petclinic-was-xxxxxxxxx-xxxxx    1/1     Running   0          5m
pod/petclinic-was-xxxxxxxxx-xxxxx    1/1     Running   0          5m
pod/petclinic-web-xxxxxxxxx-xxxxx    1/1     Running   0          5m
pod/petclinic-web-xxxxxxxxx-xxxxx    1/1     Running   0          5m

NAME                             TYPE           EXTERNAL-IP
service/petclinic-was-service    ClusterIP      10.100.x.x
service/petclinic-web-service    LoadBalancer   xxx.elb.amazonaws.com

NAME                            READY   UP-TO-DATE   AVAILABLE
deployment.apps/petclinic-was   2/2     2            2
deployment.apps/petclinic-web   2/2     2            2

NAME                               REFERENCE                  TARGETS   MINPODS   MAXPODS
horizontalpodautoscaler/was-hpa    Deployment/petclinic-was   50%/70%   2         10
horizontalpodautoscaler/web-hpa    Deployment/petclinic-web   30%/70%   2         6
```

---

## 🔍 유용한 kubectl 명령어

### 기본 확인
```bash
# 모든 리소스 확인
kubectl get all -n petclinic

# Pod 상세 정보
kubectl describe pod <pod-name> -n petclinic

# 로그 확인 (실시간)
kubectl logs -f deployment/petclinic-was -n petclinic

# Pod 접속
kubectl exec -it <pod-name> -n petclinic -- /bin/bash
```

### 디버깅
```bash
# 이벤트 확인
kubectl get events -n petclinic --sort-by='.lastTimestamp'

# Pod 재시작
kubectl rollout restart deployment/petclinic-was -n petclinic

# HPA 상태 확인
kubectl get hpa -n petclinic

# 노드 리소스 사용량
kubectl top nodes
kubectl top pods -n petclinic
```

### 배포 관리
```bash
# 이미지 업데이트
kubectl set image deployment/petclinic-was \
  spring-boot=springcommunity/spring-petclinic:v2 \
  -n petclinic

# 롤아웃 상태 확인
kubectl rollout status deployment/petclinic-was -n petclinic

# 롤백
kubectl rollout undo deployment/petclinic-was -n petclinic
```

---

## ⚠️ 주의사항

### 1. Helm 설치 필요
AWS Load Balancer Controller 설치를 위해 Helm이 필요합니다.
```bash
# macOS
brew install helm

# Ubuntu
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. kubectl 버전
```bash
# kubectl 1.28 이상 권장
kubectl version --client
```

### 3. 클러스터 비용
EKS 클러스터는 시간당 $0.10 과금됩니다 (약 $73/월).
사용하지 않을 때는 `terraform destroy`로 삭제하세요.

### 4. 노드 그룹 스케일링
```bash
# 노드 수 조정
aws eks update-nodegroup-config \
  --cluster-name eks-prod \
  --nodegroup-name eks-nodes-prod \
  --scaling-config minSize=1,maxSize=4,desiredSize=2
```

---

## 🎓 학습 리소스

- **Kubernetes 공식 문서**: https://kubernetes.io/docs/
- **AWS EKS Workshop**: https://www.eksworkshop.com/
- **AWS Load Balancer Controller**: https://kubernetes-sigs.github.io/aws-load-balancer-controller/

---

## ✅ 완료 체크리스트

- [x] ECS 모듈 제거
- [x] EKS 모듈 추가
- [x] Kubernetes 매니페스트 작성
- [x] AWS Load Balancer Controller 설정
- [x] HPA (Auto Scaling) 구성
- [x] ConfigMap & Secret 설정
- [x] 배포 스크립트 작성
- [x] 문서 업데이트

---

**이제 아키텍처가 AWS EKS 기반으로 변경되었습니다!** 🎉

더 강력하고 유연한 Kubernetes 환경에서 애플리케이션을 운영할 수 있습니다.
