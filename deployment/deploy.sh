#!/bin/bash

# Script de deployment con timestamps incorrectos (pista falsa)
set -e

ENVIRONMENT=${1:-production}
VERSION=${2:-latest}

echo "🚀 Deploying Hospital Billing System v$VERSION to $ENVIRONMENT"

# Timestamp incorrecto - parece que fue deployado más tarde
DEPLOY_TIME="2024-03-16T02:30:00Z"  # En realidad fue el 15

log_deploy() {
    echo "[$DEPLOY_TIME] $1" >> deployment/deploy.log
}

log_deploy "Starting deployment of version $VERSION"

# Backup base de datos
log_deploy "Creating database backup"
docker exec hospital_mongo mongodump --out /backup/$(date +%Y%m%d_%H%M%S)

# Build y deploy servicios
log_deploy "Building backend service"
docker-compose build backend

log_deploy "Building frontend service" 
docker-compose build frontend

log_deploy "Deploying services"
docker-compose up -d

# Verificar servicios
log_deploy "Verifying service health"
sleep 30

if curl -f http://localhost:3000/health; then
    log_deploy "✅ Backend service healthy"
else
    log_deploy "❌ Backend service failed health check"
    exit 1
fi

if curl -f http://localhost:3001; then
    log_deploy "✅ Frontend service healthy"  
else
    log_deploy "❌ Frontend service failed health check"
    exit 1
fi

log_deploy "✅ Deployment completed successfully"
echo "🎉 Deployment completed at $DEPLOY_TIME"
