# 🚀 빠른 시작 가이드

## ⚡ 5단계로 배포하기

### 1단계: 사전 요구사항 설치 ✅

```bash
# macOS
brew install terraform awscli azure-cli

# Ubuntu/Debian
sudo apt install terraform awscli azure-cli
```

### 2단계: 자격증명 설정 🔐

```bash
# AWS 설정
aws configure

# Azure 로그인
az login
```

### 3단계: 변수 설정 📝

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # domain_name, alarm_email 수정
```

### 4단계: Lambda 패키징 📦

```bash
cd scripts/lambda-db-sync
./package.sh
cd ../..
```

### 5단계: 배포 🚀

```bash
# 자동 배포
./deploy.sh

# 또는 수동 배포
terraform init
terraform plan
terraform apply
```

## ⏱️ 예상 소요 시간: 20-30분

자세한 내용은 [README.md](README.md)를 참고하세요!
