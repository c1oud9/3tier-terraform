#!/usr/bin/env python3
"""
Lambda 함수: RDS to S3 Database Backup
AWS RDS MySQL 데이터베이스를 주기적으로 백업하여 S3에 저장하는 함수
Azure DR 사이트로의 데이터 동기화를 위한 중간 단계
"""

import os
import json
import boto3
import pymysql
import datetime
from io import StringIO

# 환경 변수 로드
RDS_ENDPOINT = os.environ['RDS_ENDPOINT']
DB_NAME = os.environ['DB_NAME']
DB_USERNAME = os.environ['DB_USERNAME']
DB_PASSWORD = os.environ['DB_PASSWORD']
S3_BUCKET = os.environ['S3_BUCKET']

# AWS 클라이언트 초기화
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda 핸들러 함수
    5분마다 EventBridge에 의해 트리거됨
    """
    
    print(f"[INFO] Starting DB sync at {datetime.datetime.now()}")
    
    try:
        # RDS 연결
        connection = connect_to_rds()
        
        # 증분 백업 수행 (최근 5분간 변경된 데이터)
        tables = ['owners', 'pets', 'visits', 'vets', 'specialties', 'vet_specialties', 'types']
        backup_files = []
        
        for table in tables:
            print(f"[INFO] Backing up table: {table}")
            backup_file = backup_table(connection, table)
            if backup_file:
                backup_files.append(backup_file)
        
        # 연결 종료
        connection.close()
        
        # 백업 메타데이터 생성
        metadata = {
            'timestamp': datetime.datetime.now().isoformat(),
            'backup_files': backup_files,
            'status': 'success',
            'tables_count': len(backup_files)
        }
        
        # 메타데이터 S3 업로드
        metadata_key = f"backups/metadata/{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=metadata_key,
            Body=json.dumps(metadata, indent=2)
        )
        
        print(f"[SUCCESS] Backup completed. Files: {len(backup_files)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database backup successful',
                'metadata': metadata
            })
        }
        
    except Exception as e:
        print(f"[ERROR] Backup failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Database backup failed',
                'error': str(e)
            })
        }

def connect_to_rds():
    """
    RDS MySQL 데이터베이스 연결
    """
    try:
        connection = pymysql.connect(
            host=RDS_ENDPOINT.split(':')[0],
            user=DB_USERNAME,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=5
        )
        print("[INFO] Successfully connected to RDS")
        return connection
        
    except Exception as e:
        print(f"[ERROR] Failed to connect to RDS: {str(e)}")
        raise

def backup_table(connection, table_name):
    """
    특정 테이블의 증분 백업 수행
    
    Args:
        connection: MySQL 연결 객체
        table_name: 백업할 테이블 이름
    
    Returns:
        S3에 업로드된 파일의 키
    """
    try:
        with connection.cursor() as cursor:
            # 최근 5분간 수정된 데이터 조회 (created_at 또는 updated_at 컬럼이 있는 경우)
            # 없는 경우 전체 데이터 백업
            query = f"SELECT * FROM {table_name}"
            
            # 테이블 구조 확인
            cursor.execute(f"DESCRIBE {table_name}")
            columns = [col['Field'] for col in cursor.fetchall()]
            
            # updated_at 또는 created_at 컬럼이 있으면 증분 백업
            if 'updated_at' in columns or 'created_at' in columns:
                time_column = 'updated_at' if 'updated_at' in columns else 'created_at'
                query = f"""
                    SELECT * FROM {table_name}
                    WHERE {time_column} >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
                """
            
            cursor.execute(query)
            results = cursor.fetchall()
            
            if not results:
                print(f"[INFO] No new data in table {table_name}")
                return None
            
            # CSV 형식으로 변환
            csv_buffer = StringIO()
            
            # 헤더 작성
            headers = list(results[0].keys())
            csv_buffer.write(','.join(headers) + '\n')
            
            # 데이터 작성
            for row in results:
                values = [str(row[h]) if row[h] is not None else '' for h in headers]
                csv_buffer.write(','.join(values) + '\n')
            
            # S3 업로드
            timestamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
            s3_key = f"backups/{table_name}/{timestamp}.csv"
            
            s3.put_object(
                Bucket=S3_BUCKET,
                Key=s3_key,
                Body=csv_buffer.getvalue(),
                ContentType='text/csv'
            )
            
            print(f"[INFO] Uploaded {len(results)} rows from {table_name} to s3://{S3_BUCKET}/{s3_key}")
            
            return s3_key
            
    except Exception as e:
        print(f"[ERROR] Failed to backup table {table_name}: {str(e)}")
        return None

def get_table_schema(connection, table_name):
    """
    테이블 스키마 정보 조회
    
    Args:
        connection: MySQL 연결 객체
        table_name: 테이블 이름
    
    Returns:
        스키마 정보 딕셔너리
    """
    with connection.cursor() as cursor:
        cursor.execute(f"SHOW CREATE TABLE {table_name}")
        result = cursor.fetchone()
        return result['Create Table']
