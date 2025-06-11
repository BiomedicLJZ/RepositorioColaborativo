#!/bin/bash

# =============================================================================
# CONFIGURACIÓN DOCKER Y HERRAMIENTAS ADICIONALES PARA FUSIÓN DE EQUIPOS
# =============================================================================
# Script complementario para configurar Docker, bases de datos,
# y herramientas de desarrollo avanzadas
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
    
    # Dockerfile multi-stage para desarrollo y producción
    cat > Dockerfile << 'EOF'
# Dockerfile multi-stage para fusión de equipos
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Desarrollo
FROM node:18-alpine AS development
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000 9229
CMD ["npm", "run", "dev"]

# Build
FROM base AS build
COPY . .
RUN npm ci && npm run build

# Producción
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=base /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./
USER node
EXPOSE 3000
CMD ["npm", "start"]
EOF

    # Docker Compose para desarrollo
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Aplicación principal
  app:
    build:
      context: .
      target: development
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
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

  # Base de datos PostgreSQL
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

  # Redis para caché
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - fusion-network

  # Nginx para reverse proxy
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

  # Herramientas de monitoreo
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

    # Docker Compose para producción
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
    
    # Script de inicialización de DB
    cat > database/init/01-init.sql << 'EOF'
-- Inicialización de base de datos para proyecto fusionado
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de usuarios (fusión de ambos equipos)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    team_origin VARCHAR(20) CHECK (team_origin IN ('team_a', 'team_b', 'merged')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de configuraciones por equipo
CREATE TABLE team_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_name VARCHAR(50) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    migrated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de migración de datos
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

-- Índices para optimización
CREATE INDEX idx_users_team_origin ON users(team_origin);
CREATE INDEX idx_team_configs_team_name ON team_configs(team_name);
CREATE INDEX idx_migration_log_status ON migration_log(status);

-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

    # Script de migración de datos
    cat > database/migrations/migrate_teams.sql << 'EOF'
-- Script de migración de datos entre equipos
BEGIN;

-- Migrar usuarios del Team A (ejemplo)
INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_a_' || username as username,
    password_hash,
    'team_a'
FROM team_a_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_a_legacy_users.email
);

-- Migrar usuarios del Team B (ejemplo)
INSERT INTO users (email, username, password_hash, team_origin)
SELECT 
    email,
    'team_b_' || username as username,
    password_hash,
    'team_b'
FROM team_b_legacy_users
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.email = team_b_legacy_users.email
);

-- Log de migración
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

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    server {
        listen 80;
        server_name localhost;

        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name localhost;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # API endpoints
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Auth endpoints with stricter limits
        location /api/auth/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Static files
        location /static/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Health check
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
    
    # Configuración Prometheus
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

    # Dashboard Grafana básico
    cat > monitoring/grafana/fusion-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Fusion Project Monitoring",
    "panels": [
      {
        "title": "HTTP Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Database Connections",
        "type": "stat",
        "targets": [
          {
            "expr": "pg_stat_database_numbackends",
            "legendFormat": "Active connections"
          }
        ]
      }
    ]
  }
}
EOF

    log "Configuración de monitoreo completada"
}

# =============================================================================
# SCRIPTS DE DESARROLLO
# =============================================================================

create_dev_scripts() {
    log "Creando scripts de desarrollo..."
    
    mkdir -p scripts/dev
    
    # Script para desarrollo local
    cat > scripts/dev/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando entorno de desarrollo fusionado..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado"
    exit 1
fi

# Crear certificados SSL para desarrollo
if [ ! -f "./nginx/ssl/cert.pem" ]; then
    echo "🔐 Generando certificados SSL para desarrollo..."
    mkdir -p nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
fi

# Iniciar servicios
echo "🐳 Iniciando contenedores..."
docker-compose up -d

# Esperar a que la base de datos esté lista
echo "⏳ Esperando a que PostgreSQL esté listo..."
until docker-compose exec postgres pg_isready -U fusion_user -d fusion_db; do
    sleep 2
done

# Ejecutar migraciones
echo "🗄️ Ejecutando migraciones de base de datos..."
docker-compose exec app npm run migrate

echo "✅ Entorno de desarrollo listo!"
echo "🌐 Aplicación: https://localhost"
echo "📊 Grafana: http://localhost:3001 (admin/admin)"
echo "🔍 Prometheus: http://localhost:9090"
echo "🗄️ PostgreSQL: localhost:5432"
EOF

    # Script para tests de integración
    cat > scripts/dev/test-integration.sh << 'EOF'
#!/bin/bash
echo "🧪 Ejecutando tests de integración para fusión..."

# Levantar entorno de testing
docker-compose -f docker-compose.test.yml up -d

# Esperar servicios
sleep 10

# Ejecutar tests
docker-compose -f docker-compose.test.yml exec app npm run test:integration

# Limpiar
docker-compose -f docker-compose.test.yml down -v

echo "✅ Tests de integración completados"
EOF

    # Script para backup de datos
    cat > scripts/dev/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./database/backup"
DATE=$(date +%Y%m%d_%H%M%S)

echo "💾 Creando backup de base de datos..."

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker-compose exec postgres pg_dump -U fusion_user fusion_db > "$BACKUP_DIR/fusion_db_$DATE.sql"

# Backup Redis
docker-compose exec redis redis-cli BGSAVE
docker cp $(docker-compose ps -q redis):/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

echo "✅ Backup completado en $BACKUP_DIR"
EOF

    chmod +x scripts/dev/*.sh
    
    log "Scripts de desarrollo creados"
}

# =============================================================================
# CONFIGURACIÓN DE TESTING E2E
# =============================================================================

setup_e2e_testing() {
    log "Configurando testing E2E..."
    
    # Cypress configuration
    cat > cypress.config.js << 'EOF'
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'https://localhost',
    supportFile: 'cypress/support/e2e.js',
    specPattern: 'cypress/e2e/**/*.cy.{js,ts}',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true,
    env: {
      TEAM_A_USER: 'team_a_test_user',
      TEAM_B_USER: 'team_b_test_user',
      FUSION_USER: 'fusion_test_user'
    }
  }
})
EOF

    mkdir -p cypress/{e2e,support,fixtures}
    
    # Test E2E para funcionalidades fusionadas
    cat > cypress/e2e/fusion-workflow.cy.js << 'EOF'
describe('Fusion Workflow', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  it('should allow Team A user to login and access merged features', () => {
    cy.get('[data-cy=login-button]').click()
    cy.get('[data-cy=username]').type(Cypress.env('TEAM_A_USER'))
    cy.get('[data-cy=password]').type('password123')
    cy.get('[data-cy=submit]').click()
    
    // Verificar acceso a funcionalidades fusionadas
    cy.get('[data-cy=fusion-dashboard]').should('be.visible')
    cy.get('[data-cy=team-a-features]').should('be.visible')
    cy.get('[data-cy=shared-features]').should('be.visible')
  })

  it('should allow Team B user to access migrated features', () => {
    cy.get('[data-cy=login-button]').click()
    cy.get('[data-cy=username]').type(Cypress.env('TEAM_B_USER'))
    cy.get('[data-cy=password]').type('password123')
    cy.get('[data-cy=submit]').click()
    
    // Verificar migración exitosa
    cy.get('[data-cy=team-b-legacy]').should('be.visible')
    cy.get('[data-cy=migrated-features]').should('be.visible')
  })

  it('should handle cross-team collaboration features', () => {
    // Login como usuario fusionado
    cy.get('[data-cy=login-button]').click()
    cy.get('[data-cy=username]').type(Cypress.env('FUSION_USER'))
    cy.get('[data-cy=password]').type('password123')
    cy.get('[data-cy=submit]').click()
    
    // Verificar colaboración entre equipos
    cy.get('[data-cy=collaboration-tools]').click()
    cy.get('[data-cy=team-a-data]').should('be.visible')
    cy.get('[data-cy=team-b-data]').should('be.visible')
    cy.get('[data-cy=unified-view]').should('be.visible')
  })
})
EOF

    log "Testing E2E configurado"
}

# =============================================================================
# ARCHIVO DE VARIABLES DE ENTORNO
# =============================================================================

create_env_files() {
    log "Creando archivos de configuración de entorno..."
    
    # .env para desarrollo
    cat > .env.development << 'EOF'
# Configuración de desarrollo para proyecto fusionado
NODE_ENV=development
PORT=3000
DEBUG_PORT=9229

# Base de datos
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fusion_db
DB_USER=fusion_user
DB_PASSWORD=fusion_pass

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=dev_secret_key_change_in_production
JWT_EXPIRES_IN=24h

# Team-specific configs
TEAM_A_API_URL=http://localhost:3001
TEAM_B_API_URL=http://localhost:3002
LEGACY_MIGRATION_MODE=true

# Logging
LOG_LEVEL=debug
LOG_FORMAT=dev

# Rate limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

    # .env para producción (template)
    cat > .env.production.template << 'EOF'
# Configuración de producción - CAMBIAR TODOS LOS VALORES
NODE_ENV=production
PORT=3000

# Base de datos
DB_HOST=your_db_host
DB_PORT=5432
DB_NAME=fusion_prod_db
DB_USER=fusion_prod_user
DB_PASSWORD=CHANGE_THIS_PASSWORD

# Redis
REDIS_HOST=your_redis_host
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_THIS_PASSWORD

# JWT
JWT_SECRET=CHANGE_THIS_VERY_LONG_RANDOM_SECRET
JWT_EXPIRES_IN=1h

# Seguridad
CORS_ORIGIN=https://your-domain.com
HELMET_ENABLED=true
RATE_LIMIT_ENABLED=true

# Monitoreo
SENTRY_DSN=your_sentry_dsn
PROMETHEUS_ENABLED=true

# SSL
SSL_CERT_PATH=/etc/letsencrypt/live/your-domain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/your-domain.com/privkey.pem
EOF

    log "Archivos de entorno creados"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    log "=== CONFIGURACIÓN DOCKER Y HERRAMIENTAS ADICIONALES ==="
    
    setup_docker_environment
    setup_database
    setup_nginx
    setup_monitoring
    create_dev_scripts
    setup_e2e_testing
    create_env_files
    
    log "=== CONFIGURACIÓN ADICIONAL COMPLETADA ==="
    echo ""
    echo -e "${GREEN}🐳 Docker y herramientas adicionales configuradas!${
