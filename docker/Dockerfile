# ===================================================
# Spring PetClinic Dockerfile (Multi-stage Build)
# MySQL Profile 활성화된 프로덕션 이미지
# ===================================================

# ============= Stage 1: Build =============
FROM maven:3.9-eclipse-temurin-21 AS builder

# 작업 디렉토리 설정
WORKDIR /app

# pom.xml 먼저 복사 (의존성 캐싱 최적화)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 소스 코드 복사
COPY src ./src

# 애플리케이션 빌드 (테스트 스킵)
RUN mvn clean package -DskipTests -Dspring-boot.run.profiles=mysql

# ============= Stage 2: Runtime =============
FROM eclipse-temurin:21-jre-alpine

# 메타데이터 라벨
LABEL maintainer="AWS2 Team"
LABEL application="spring-petclinic"
LABEL version="3.3.0"

# 비root 사용자 생성 (보안)
RUN addgroup -S spring && adduser -S spring -G spring

# 작업 디렉토리 설정
WORKDIR /app

# 빌드 스테이지에서 JAR 파일 복사
COPY --from=builder /app/target/*.jar app.jar

# 소유권 변경
RUN chown spring:spring app.jar

# 사용자 전환
USER spring:spring

# 포트 노출
EXPOSE 8080

# Health Check 설정
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# JVM 옵션 설정 (환경변수로 오버라이드 가능)
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 애플리케이션 실행
# MySQL 프로파일 활성화 및 환경변수 주입
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar --spring.profiles.active=mysql"]
