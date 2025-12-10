# VPN 연결 및 DB 동기화 설정 가이드

## 개요

현재 아키텍처에서는 **자동으로 연결되지 않습니다**. 다음 두 가지를 수동으로 설정해야 합니다:

1. **VPN 연결 확인 및 검증**
2. **DB 동기화 설정**

---

## 1. VPN 연결 설정

### 1.1 배포 순서

```bash
# Step 1: AWS 인프라 배포
cd aws
terraform init
terraform apply

# Step 2: VPN Tunnel IP 확인
terraform output vpn_connection_tunnel1_address
# 출력 예: 52.79.123.45

# Step 3: Azure terraform.tfvars 업데이트
cd ../azure
# terraform.tfvars에서 aws_vpn_gateway_ip 값을 위의 IP로 변경

# Step 4: Azure 인프라 배포
terraform init
terraform apply
```

### 1.2 VPN 연결 상태 확인

**AWS 측 확인:**
```bash
# VPN 연결 ID 확인
cd aws
terraform output vpn_connection_id

# VPN 터널 상태 확인
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <VPN_CONNECTION_ID> \
  --region ap-northeast-2 \
  --query 'VpnConnections[0].VgwTelemetry' \
  --output table

# 정상 상태: Status가 "UP"이어야 함
```

**Azure 측 확인:**
```bash
# VPN 연결 상태 확인
az network vpn-connection show \
  --name vpn-to-aws-prod \
  --resource-group rg-dr-prod \
  --query connectionStatus

# 정상 상태: "Connected" 또는 "Connecting"
```

### 1.3 VPN 트러블슈팅

VPN이 연결되지 않는 경우:

1. **Pre-Shared Key 확인**
   ```bash
   # AWS와 Azure의 vpn_shared_key가 동일한지 확인
   # aws/terraform.tfvars
   # azure/terraform.tfvars
   ```

2. **IPsec 설정 일치 확인**
   - IKE Version: ikev2
   - Encryption: AES256
   - Integrity: SHA2-256
   - DH Group: 2

3. **라우팅 테이블 확인**
   ```bash
   # AWS에서 Azure CIDR로 가는 라우트 확인
   aws ec2 describe-route-tables \
     --filters "Name=vpc-id,Values=<VPC_ID>" \
     --query 'RouteTables[].Routes'
   
   # 172.16.0.0/16 -> VPN Gateway로 라우팅되어야 함
   ```

4. **네트워크 연결 테스트**
   ```bash
   # AWS EKS Pod에서 Azure VM으로 ping 테스트
   kubectl run test-pod --image=nicolaka/netshoot -it --rm
   # Pod 내에서:
   ping 172.16.11.10  # Azure Web VM Private IP
   ```

---

## 2. DB 동기화 설정

현재 프로젝트에는 **두 가지 옵션**이 있습니다:

### 옵션 1: Lambda 기반 정기 백업 (권장)

**특징:**
- 6시간마다 자동 백업
- RDS → S3 → Azure MySQL
- RPO: 6시간
- 비용: 저렴 (~$10/월)

**구현 방법:**

1. **Lambda 함수 배포**
   ```bash
   cd aws
   
   # Lambda 배포 패키지 생성
   cd lambda
   pip install pymysql -t .
   zip -r db_backup.zip .
   cd ..
   
   # lambda-backup.tf 파일을 aws/ 디렉토리에 추가
   terraform apply
   ```

2. **Azure Function 생성** (S3 백업 파일을 Azure MySQL로 복원)
   ```bash
   # Azure Function 코드는 별도로 제공
   cd azure
   # Azure Function을 Terraform에 추가하거나 수동 배포
   ```

3. **백업 스케줄 조정**
   ```hcl
   # aws/lambda-backup.tf에서
   schedule_expression = "rate(6 hours)"  # 필요시 변경
   # rate(1 hour), rate(12 hours), cron(0 0 * * ? *) 등
   ```

### 옵션 2: AWS DMS 실시간 복제 (고급)

**특징:**
- 실시간 CDC (Change Data Capture)
- RPO: 거의 0
- RTO: 빠름
- 비용: 높음 (~$200/월, dms.t3.medium 기준)

**구현 방법:**

1. **DMS 활성화**
   ```bash
   cd aws
   
   # dms.tf.bak 파일을 dms.tf로 이름 변경
   mv dms.tf.bak dms.tf
   
   # variables.tf에 Azure MySQL 정보 추가
   # terraform.tfvars에서 값 설정
   terraform apply
   ```

2. **필요한 변수 추가**
   ```hcl
   # aws/variables.tf에 추가
   variable "azure_mysql_private_ip" {
     description = "Azure MySQL Private IP"
     type        = string
   }
   
   variable "azure_mysql_username" {
     description = "Azure MySQL Username"
     type        = string
   }
   
   variable "azure_mysql_password" {
     description = "Azure MySQL Password"
     type        = string
     sensitive   = true
   }
   ```

3. **Azure MySQL 설정**
   ```bash
   # Azure MySQL에서 AWS DMS 접근 허용
   # Azure Portal에서:
   # MySQL Flexible Server → Networking
   # → Virtual Network에서 AWS VPN 연결 허용
   ```

---

## 3. 동기화 검증

### 3.1 Lambda 백업 방식 검증

```bash
# 1. Lambda 수동 실행
aws lambda invoke \
  --function-name rds-backup-to-s3-prod \
  --region ap-northeast-2 \
  response.json

# 2. S3 백업 파일 확인
aws s3 ls s3://dr-backup-prod-<ACCOUNT_ID>/backups/prod/

# 3. CloudWatch Logs 확인
aws logs tail /aws/lambda/rds-backup-to-s3-prod --follow

# 4. Azure MySQL에 복원 확인
ssh azureuser@<AZURE_WEB_VM_IP>
mysql -h <AZURE_MYSQL_FQDN> -u mysqladmin -p
mysql> SHOW DATABASES;
mysql> USE petclinic;
mysql> SHOW TABLES;
```

### 3.2 DMS 방식 검증

```bash
# 1. DMS 복제 상태 확인
aws dms describe-replication-tasks \
  --filters "Name=replication-task-arn,Values=<TASK_ARN>" \
  --query 'ReplicationTasks[0].Status'

# 2. 복제 지표 확인
aws cloudwatch get-metric-statistics \
  --namespace AWS/DMS \
  --metric-name CDCLatencySource \
  --dimensions Name=ReplicationTaskIdentifier,Value=dms-task-prod \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average

# 3. 데이터 동기화 테스트
# AWS RDS에 테스트 데이터 삽입
mysql -h <RDS_ENDPOINT> -u admin -p
mysql> USE petclinic;
mysql> INSERT INTO owners (first_name, last_name) VALUES ('Test', 'User');

# Azure MySQL에서 확인 (30초~1분 후)
mysql -h <AZURE_MYSQL_FQDN> -u mysqladmin -p
mysql> USE petclinic;
mysql> SELECT * FROM owners WHERE first_name = 'Test';
```

---

## 4. 비용 비교

| 방식 | RPO | RTO | 월 비용 (예상) | 복잡도 |
|------|-----|-----|---------------|--------|
| Lambda 백업 (6시간) | 6시간 | 수동 복원 (~30분) | $10 | 낮음 |
| Lambda 백업 (1시간) | 1시간 | 수동 복원 (~30분) | $30 | 낮음 |
| AWS DMS (실시간) | ~0 | 자동 (~5분) | $200 | 높음 |

---

## 5. 권장 사항

**프로젝트 발표용:**
- **Lambda 백업 방식** 사용
- 6시간 주기로 충분함
- 비용 효율적이고 구현 간단

**실제 운영 환경:**
- RPO < 1시간 필요 시: AWS DMS
- RPO 1~6시간 허용 시: Lambda 백업
- 비용 제약 있을 시: Lambda 백업

---

## 6. 체크리스트

배포 전 확인:
- [ ] AWS 인프라 배포 완료
- [ ] VPN Tunnel IP 확인 및 Azure에 입력
- [ ] Azure 인프라 배포 완료
- [ ] VPN 연결 상태 "Connected" 확인
- [ ] AWS → Azure 네트워크 연결 테스트
- [ ] Lambda 백업 함수 배포 (또는 DMS 활성화)
- [ ] 백업 스케줄 설정
- [ ] 첫 백업 수동 실행 및 검증
- [ ] CloudWatch 알람 설정
- [ ] 복원 절차 문서화

---

## 문의

추가 질문이나 문제 발생 시:
1. CloudWatch Logs 확인
2. VPN 상태 재확인
3. Security Group 규칙 확인
4. Terraform 상태 확인: `terraform show`
