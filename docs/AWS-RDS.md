# 🗄️ Guia de Configuração AWS RDS com Read Replicas

Este guia explica como configurar manualmente o RDS PostgreSQL com réplicas de leitura na AWS (caso não queira usar Terraform).

## 📋 Pré-requisitos

- Conta AWS ativa
- AWS CLI configurado
- Conhecimento básico do Console AWS

## 🚀 Passo a Passo

### 1. Criar VPC e Subnets (Opcional)

Se já tem uma VPC, pule para o passo 2.

```bash
# Via CLI
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=url-shortener-vpc}]'

# Criar subnets em diferentes AZs
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
```

Ou use o Console: **VPC > Create VPC**

### 2. Criar DB Subnet Group

Console AWS: **RDS > Subnet groups > Create DB subnet group**

- **Name**: `url-shortener-db-subnet`
- **VPC**: Selecione sua VPC
- **Availability Zones**: Selecione pelo menos 2
- **Subnets**: Selecione subnets em diferentes AZs

Via CLI:
```bash
aws rds create-db-subnet-group \
    --db-subnet-group-name url-shortener-db-subnet \
    --db-subnet-group-description "Subnet group for URL Shortener" \
    --subnet-ids subnet-xxxxx subnet-yyyyy
```

### 3. Criar Security Group

Console: **EC2 > Security Groups > Create security group**

- **Name**: `url-shortener-rds-sg`
- **VPC**: Sua VPC
- **Inbound rules**:
  - Type: PostgreSQL
  - Protocol: TCP
  - Port: 5432
  - Source: Security group do EC2 ou CIDR da VPC

Via CLI:
```bash
# Criar security group
aws ec2 create-security-group \
    --group-name url-shortener-rds-sg \
    --description "Security group for RDS" \
    --vpc-id vpc-xxxxx

# Adicionar regra
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxx \
    --protocol tcp \
    --port 5432 \
    --source-group sg-yyyyy  # SG do EC2
```

### 4. Criar RDS Master Instance

Console: **RDS > Databases > Create database**

#### Engine options
- **Engine type**: PostgreSQL
- **Version**: PostgreSQL 15.4
- **Template**: Production

#### Settings
- **DB instance identifier**: `url-shortener-master`
- **Master username**: `dbadmin`
- **Master password**: `SuaSenhaSegura123!` (mínimo 16 caracteres)

#### Instance configuration
- **DB instance class**: `db.t3.medium` (2 vCPU, 4 GB RAM)
  - Para produção pesada: `db.r6g.large` ou maior

#### Storage
- **Storage type**: General Purpose SSD (gp3)
- **Allocated storage**: 100 GB
- **Storage autoscaling**: Habilitado (máximo 1000 GB)

#### Availability & durability
- **Multi-AZ deployment**: ✅ **Habilitado** (recomendado para produção)

#### Connectivity
- **VPC**: Sua VPC
- **DB Subnet group**: `url-shortener-db-subnet`
- **Public access**: ❌ **Não** (recomendado)
- **VPC security group**: `url-shortener-rds-sg`
- **Availability Zone**: No preference

#### Database authentication
- **Password authentication**: Habilitado

#### Additional configuration
- **Initial database name**: `shortener_db`
- **DB parameter group**: default.postgres15
- **Backup retention period**: 7 days
- **Backup window**: 03:00-04:00 UTC
- **Maintenance window**: Mon:04:00-Mon:05:00 UTC
- **Enhanced monitoring**: ✅ Habilitado (60 segundos)
- **Performance Insights**: ✅ Habilitado
- **Encryption**: ✅ Habilitado

Via CLI:
```bash
aws rds create-db-instance \
    --db-instance-identifier url-shortener-master \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --engine-version 15.4 \
    --master-username dbadmin \
    --master-user-password 'SuaSenhaSegura123!' \
    --allocated-storage 100 \
    --storage-type gp3 \
    --storage-encrypted \
    --db-name shortener_db \
    --vpc-security-group-ids sg-xxxxx \
    --db-subnet-group-name url-shortener-db-subnet \
    --backup-retention-period 7 \
    --preferred-backup-window 03:00-04:00 \
    --preferred-maintenance-window Mon:04:00-Mon:05:00 \
    --multi-az \
    --enable-cloudwatch-logs-exports postgresql upgrade \
    --enable-performance-insights \
    --monitoring-interval 60 \
    --publicly-accessible false
```

**Aguarde**: A criação leva ~10-15 minutos

### 5. Verificar Master Instance

```bash
# Obter status
aws rds describe-db-instances \
    --db-instance-identifier url-shortener-master \
    --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
    --output table

# Quando aparecer "available", copie o endpoint
```

### 6. Criar Read Replica 1

Console: **RDS > Databases > url-shortener-master > Actions > Create read replica**

- **DB instance identifier**: `url-shortener-replica-1`
- **DB instance class**: `db.t3.medium` (mesmo do master)
- **Availability Zone**: `us-east-1b` (diferente do master)
- **Multi-AZ**: Não (réplicas não precisam)
- **Public access**: Não
- **Monitoring**: Habilitado

Via CLI:
```bash
aws rds create-db-instance-read-replica \
    --db-instance-identifier url-shortener-replica-1 \
    --source-db-instance-identifier url-shortener-master \
    --db-instance-class db.t3.medium \
    --availability-zone us-east-1b \
    --publicly-accessible false \
    --enable-cloudwatch-logs-exports postgresql \
    --enable-performance-insights \
    --monitoring-interval 60
```

### 7. Criar Read Replica 2

Repita o processo:

```bash
aws rds create-db-instance-read-replica \
    --db-instance-identifier url-shortener-replica-2 \
    --source-db-instance-identifier url-shortener-master \
    --db-instance-class db.t3.medium \
    --availability-zone us-east-1c \
    --publicly-accessible false \
    --enable-cloudwatch-logs-exports postgresql \
    --enable-performance-insights \
    --monitoring-interval 60
```

### 8. Criar Read Replica 3

```bash
aws rds create-db-instance-read-replica \
    --db-instance-identifier url-shortener-replica-3 \
    --source-db-instance-identifier url-shortener-master \
    --db-instance-class db.t3.medium \
    --availability-zone us-east-1a \
    --publicly-accessible false \
    --enable-cloudwatch-logs-exports postgresql \
    --enable-performance-insights \
    --monitoring-interval 60
```

**Aguarde**: Cada réplica leva ~10-15 minutos

### 9. Obter Endpoints

```bash
# Master
aws rds describe-db-instances \
    --db-instance-identifier url-shortener-master \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text

# Réplica 1
aws rds describe-db-instances \
    --db-instance-identifier url-shortener-replica-1 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text

# Réplica 2
aws rds describe-db-instances \
    --db-instance-identifier url-shortener-replica-2 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text

# Réplica 3
aws rds describe-db-instances \
    --db-instance-identifier url-shortener-replica-3 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
```

### 10. Configurar Connection Strings

Atualize seu `backend/.env`:

```bash
DATABASE_WRITE_URL=postgresql+asyncpg://dbadmin:SuaSenhaSegura123!@url-shortener-master.xxxxxx.us-east-1.rds.amazonaws.com:5432/shortener_db

DATABASE_READ_URLS=postgresql+asyncpg://dbadmin:SuaSenhaSegura123!@url-shortener-replica-1.xxxxxx.us-east-1.rds.amazonaws.com:5432/shortener_db,postgresql+asyncpg://dbadmin:SuaSenhaSegura123!@url-shortener-replica-2.xxxxxx.us-east-1.rds.amazonaws.com:5432/shortener_db,postgresql+asyncpg://dbadmin:SuaSenhaSegura123!@url-shortener-replica-3.xxxxxx.us-east-1.rds.amazonaws.com:5432/shortener_db
```

### 11. Testar Conexão

Do seu EC2:

```bash
# Instalar cliente PostgreSQL
sudo apt update
sudo apt install postgresql-client -y

# Testar master
psql -h url-shortener-master.xxxxx.us-east-1.rds.amazonaws.com \
     -U dbadmin \
     -d shortener_db \
     -c "SELECT version();"

# Testar réplica
psql -h url-shortener-replica-1.xxxxx.us-east-1.rds.amazonaws.com \
     -U dbadmin \
     -d shortener_db \
     -c "SELECT version();"
```

### 12. Executar Migrações

```bash
# No EC2, com backend deployado
docker exec -it shortener_api alembic upgrade head
```

## 📊 Monitoramento

### CloudWatch Metrics
- **CPU Utilization**: < 70%
- **Database Connections**: < 80% do max
- **Read Latency**: < 10ms
- **Write Latency**: < 20ms
- **Replica Lag**: < 100ms

### Performance Insights
Console: **RDS > url-shortener-master > Performance Insights**

Verifique:
- Top SQL queries
- Wait events
- Database load

### Alarmes Recomendados

```bash
# CPU alto
aws cloudwatch put-metric-alarm \
    --alarm-name rds-cpu-high \
    --alarm-description "RDS CPU > 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=url-shortener-master

# Replication lag alto
aws cloudwatch put-metric-alarm \
    --alarm-name rds-replica-lag-high \
    --alarm-description "Replica lag > 1000ms" \
    --metric-name ReplicaLag \
    --namespace AWS/RDS \
    --statistic Average \
    --period 60 \
    --threshold 1000 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=url-shortener-replica-1
```

## 💰 Custos Estimados (us-east-1)

### RDS PostgreSQL

| Instância | Tipo | vCPU | RAM | Preço/hora | Preço/mês |
|-----------|------|------|-----|-----------|-----------|
| Master Multi-AZ | db.t3.medium | 2 | 4 GB | $0.136 | ~$100 |
| Réplica 1 | db.t3.medium | 2 | 4 GB | $0.068 | ~$50 |
| Réplica 2 | db.t3.medium | 2 | 4 GB | $0.068 | ~$50 |
| Réplica 3 | db.t3.medium | 2 | 4 GB | $0.068 | ~$50 |
| **Storage (100 GB)** | gp3 | - | - | - | ~$12 |
| **Backups (100 GB)** | - | - | - | - | ~$10 |
| **Total** | | | | | **~$272/mês** |

### Otimização de Custos

1. **Use Reserved Instances**: Economize até 60%
2. **Ajuste o tipo de instância**: db.t3.small para ambientes menores
3. **Reduza réplicas**: Comece com 1 réplica, escale conforme necessário
4. **Aurora Serverless**: Considere para workloads variáveis

## 🔧 Manutenção

### Backup Manual

```bash
aws rds create-db-snapshot \
    --db-instance-identifier url-shortener-master \
    --db-snapshot-identifier snapshot-$(date +%Y%m%d-%H%M%S)
```

### Upgrade de Versão

```bash
aws rds modify-db-instance \
    --db-instance-identifier url-shortener-master \
    --engine-version 15.5 \
    --apply-immediately
```

### Aumentar Storage

```bash
aws rds modify-db-instance \
    --db-instance-identifier url-shortener-master \
    --allocated-storage 200 \
    --apply-immediately
```

## 🚨 Troubleshooting

### Réplica com lag alto

```sql
-- No master, verificar WAL
SELECT pg_current_wal_lsn();

-- Na réplica, verificar progresso
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
```

### Conexões esgotadas

```sql
-- Verificar conexões ativas
SELECT count(*) FROM pg_stat_activity;

-- Matar conexões idle
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND state_change < current_timestamp - INTERVAL '30 minutes';
```

### Performance ruim

```sql
-- Top queries lentas
SELECT query, calls, mean_exec_time, max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## 📚 Recursos

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [PostgreSQL Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PostgreSQL.Replication.ReadReplicas.html)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)