#!/bin/bash

# =============================================================================
# CONFIGURACIÓN DOCKER Y HERRAMIENTAS ADICIONALES PARA FUSIÓN DE EQUIPOS
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# =============================================================================
# CONFIGURACIÓN DOCKER
# =============================================================================

setup_docker_environment() {
    log "Configurando entorno Docker..."

    cat > Dockerfile << 'EOF'
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS development
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000 9229
CMD ["npm", "run", "dev"]

FROM base AS build
COPY . .
RUN npm ci && npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=base /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./
USER node
EXPOSE 3000
CMD ["npm", "start"]
EOF

    cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    build:
      context: .
      target: development
    ports:
      - "3000:3000"
      - "9229:9229"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    networks:
      - fusion-network

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: fusion_db
      POSTGRES_USER: fusion_user
      POSTGRES_PASSWORD: fusion_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - fusion-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - fusion-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - app
    networks:
      - fusion-network

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - fusion-network

  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - fusion-network

volumes:
  postgres_data:
  redis_data:
  grafana_data:

networks:
  fusion-network:
    driver: bridge
EOF

    cat > docker-compose.prod.yml << 'EOF'
version: '3.8'
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    networks:
      - fusion-network

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-fusion_db}
      POSTGRES_USER: ${POSTGRES_USER:-fusion_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/backup:/backup
    restart: unless-stopped
    networks:
      - fusion-network

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - fusion-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - fusion-network

volumes:
  postgres_data:
  redis_data:

networks:
  fusion-network:
    driver: bridge
EOF

    log "Configuración Docker completada"
}

# =============================================================================
# CONFIGURACIÓN DE BASE DE DATOS
# =============================================================================

setup_database() {
    log "Configurando base de datos..."

    mkdir -p database/{init,migrations,seeds}

    cat > database/init/01-init.sql << 'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    team_origin VARCHAR(20) CHECK (team_origin IN ('team_a', 'team_b', 'merged')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE team_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_name VARCHAR(50) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    migrated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE migration_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    team_source VARCHAR(20) NOT NULL,
    records_affected INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_team_origin ON users(team_origin);
CREATE INDEX idx_team_configs_team_name ON team_configs(team_name);
CREATE INDEX idx_migration_log_status ON migration_log(status);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

    cat > database/migrations/migrate_teams.sql << 'EOF'
BEGIN;

INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_a_' || username,
    password_hash,
    'team_a'
FROM team_a_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_a_legacy_users.email
);

INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_b_' || username,
    password_hash,
    'team_b'
FROM team_b_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_b_legacy_users.email
);

INSERT INTO migration_log (table_name, operation, team_source, records_affected, status)
VALUES 
    ('users', 'migration', 'team_a', 
     (SELECT COUNT(*) FROM users WHERE team_origin = 'team_a'), 'completed'),
    ('users', 'migration', 'team_b', 
     (SELECT COUNT(*) FROM users WHERE team_origin = 'team_b'), 'completed');

COMMIT;
EOF

    log "Configuración de base de datos completada"
}

# =============================================================================
# CONFIGURACIÓN NGINX
# =============================================================================

setup_nginx() {
    log "Configurando Nginx..."

    mkdir -p nginx/{ssl,conf.d}

    cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream app_servers {
        server app:3000;
    }

    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    server {
        listen 80;
        server_name localhost;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name localhost;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256;

        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /api/auth/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        location /health {
            access_log off;
            proxy_pass http://app_servers;
        }
    }
}
EOF

    log "Configuración Nginx completada"
}

# =============================================================================
# CONFIGURACIÓN DE MONITOREO
# =============================================================================

setup_monitoring() {
    log "Configurando herramientas de monitoreo..."

    mkdir -p monitoring/{prometheus,grafana}

    cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'fusion-app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'nginx-exporter'
    static_configs:
      - targets: ['nginx-exporter:9113']
EOF

    cat > monitoring/grafana/fusion-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Fusion Project Monitoring",
    "timezone": "browser",
    "panels": [],
    "schemaVersion": 30,
    "version": 1
  }
}
EOF

    log "Herramientas de monitoreo configuradas"
}

# =============================================================================
# EJECUCIÓN
# =============================================================================

setup_docker_environment
setup_database
setup_nginx
setup_monitoring

