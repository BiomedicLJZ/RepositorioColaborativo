#!/bin/bash

# Archivos adicionales para el examen - Ejecutar después del setup principal

PROJECT_NAME="hospital-billing-system"
cd "$PROJECT_NAME"

# === DOCKERFILES ===
echo "🐳 Creando Dockerfiles..."

# Backend Dockerfile
cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Frontend Dockerfile  
cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Data Processor Dockerfile
cat > data-processor/Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "billing_processor.py"]
EOF

# === ARCHIVOS DE CONFIGURACIÓN ===
echo "⚙️ Creando archivos de configuración..."

# Nginx config para frontend
mkdir -p config/nginx
cat > config/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# === LOGS FALSOS PARA CONFUNDIR ===
echo "📝 Creando logs de sistema..."
mkdir -p logs/{backend,frontend,nginx,mongodb}

# Log de backend que no muestra el problema
cat > logs/backend/app.log << 'EOF'
2024-03-20T08:00:01Z [INFO] Server started on port 3000
2024-03-20T08:00:01Z [INFO] Connected to MongoDB
2024-03-20T08:15:23Z [INFO] GET /api/billing/today - 200 OK (45ms)
2024-03-20T08:15:23Z [INFO] Buscando facturas entre 2024-03-20T06:00:00.000Z y 2024-03-20T05:59:59.999Z
2024-03-20T08:15:23Z [INFO] Encontradas 0 facturas
2024-03-20T08:30:45Z [INFO] GET /api/billing/today - 200 OK (38ms)
2024-03-20T08:30:45Z [INFO] Buscando facturas entre 2024-03-20T06:00:00.000Z y 2024-03-20T05:59:59.999Z
2024-03-20T08:30:45Z [INFO] Encontradas 0 facturas
2024-03-20T09:00:12Z [INFO] GET /health - 200 OK (2ms)
2024-03-20T09:15:33Z [WARNING] Slow query detected: billing collection scan took 890ms
2024-03-20T09:30:21Z [INFO] GET /api/billing/today - 200 OK (52ms)
2024-03-20T09:30:21Z [INFO] Buscando facturas entre 2024-03-20T06:00:00.000Z y 2024-03-20T05:59:59.999Z
2024-03-20T09:30:21Z [INFO] Encontradas 0 facturas
EOF

# Log de MongoDB
cat > logs/mongodb/mongod.log << 'EOF'
2024-03-20T08:00:00.123Z I NETWORK  [listener] Listening on 0.0.0.0:27017
2024-03-20T08:00:01.456Z I NETWORK  [conn1] received client metadata from backend container
2024-03-20T08:15:23.789Z I COMMAND  [conn1] command hospital_billing.billings command: find { billingDate: { $gte: new Date(1710918000000), $lte: new Date(1710917999999) } } planSummary: IXSCAN { billingDate: 1 } keysExamined:0 docsExamined:0 numReturned:0 reslen:20 locks:{ Global: { acquireCount: { r: 1 } } } 45ms
2024-03-20T08:30:45.321Z I COMMAND  [conn1] command hospital_billing.billings command: find { billingDate: { $gte: new Date(1710918000000), $lte: new Date(1710917999999) } } planSummary: IXSCAN { billingDate: 1 } keysExamined:0 docsExamined:0 numReturned:0 reslen:20 locks:{ Global: { acquireCount: { r: 1 } } } 38ms
EOF

# === ARCHIVOS DE TEST (que ocultan el problema) ===
echo "🧪 Creando tests..."
mkdir -p tests

cat > tests/billing.test.js << 'EOF'
const request = require('supertest');
const app = require('../backend/server');

describe('Billing API', () => {
    test('GET /api/billing/today should return 200', async () => {
        const response = await request(app)
            .get('/api/billing/today')
            .expect(200);
        
        // Test malo - solo verifica que responda, no que tenga datos
        expect(Array.isArray(response.body)).toBe(true);
    });
    
    test('GET /health should return healthy status', async () => {
        const response = await request(app)
            .get('/health')
            .expect(200);
        
        expect(response.body.status).toBe('healthy');
    });
    
    test('POST /api/billing should create billing', async () => {
        const billingData = {
            patientId: 'TEST001',
            amount: 100.00,
            services: ['Test Service']
        };
        
        const response = await request(app)
            .post('/api/billing')
            .send(billingData)
            .expect(201);
        
        expect(response.body.patientId).toBe('TEST001');
    });
});
EOF

# === SCRIPTS DE DEPLOYMENT ===
echo "🚀 Creando scripts de deployment..."
mkdir -p deployment

cat > deployment/deploy.sh << 'EOF'
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
EOF

chmod +x deployment/deploy.sh

# Log de deployment con timestamps confusos
cat > deployment/deploy.log << 'EOF'
[2024-03-15T18:30:00Z] Starting deployment of version 2.4.7
[2024-03-15T18:31:15Z] Creating database backup
[2024-03-15T18:32:30Z] Building backend service
[2024-03-15T18:35:45Z] Building frontend service
[2024-03-15T18:38:12Z] Deploying services
[2024-03-15T18:41:30Z] Verifying service health
[2024-03-15T18:42:15Z] ✅ Backend service healthy
[2024-03-15T18:42:45Z] ✅ Frontend service healthy
[2024-03-15T18:43:00Z] ✅ Deployment completed successfully
[2024-03-16T02:30:00Z] Starting deployment of version 2.4.7
[2024-03-16T02:31:15Z] Creating database backup
[2024-03-16T02:32:30Z] Building backend service
[2024-03-16T02:35:45Z] Building frontend service
[2024-03-16T02:38:12Z] Deploying services
[2024-03-16T02:41:30Z] Verifying service health
[2024-03-16T02:42:15Z] ✅ Backend service healthy
[2024-03-16T02:42:45Z] ✅ Frontend service healthy
[2024-03-16T02:43:00Z] ✅ Deployment completed successfully
EOF

# === REPORT ENGINE (Java - más complejidad) ===
echo "☕ Creando report engine..."
cd report-engine

cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.vitaltrack</groupId>
    <artifactId>hospital-billing-reports</artifactId>
    <version>2.4.7</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>2.7.14</version>
        </dependency>
        <dependency>
            <groupId>org.mongodb</groupId>
            <artifactId>mongodb-driver-sync</artifactId>
            <version>4.10.2</version>
        </dependency>
    </dependencies>
</project>
EOF

mkdir -p src/main/java/com/vitaltrack/reports

cat > src/main/java/com/vitaltrack/reports/ReportApplication.java << 'EOF'
package com.vitaltrack.reports;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import com.mongodb.client.*;
import org.bson.Document;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

@SpringBootApplication
@RestController
public class ReportApplication {
    
    private MongoClient mongoClient;
    private MongoDatabase database;
    
    public ReportApplication() {
        mongoClient = MongoClients.create("mongodb://localhost:27017");
        database = mongoClient.getDatabase("hospital_billing");
    }
    
    @GetMapping("/reports/daily")
    public Map<String, Object> getDailyReport() {
        Map<String, Object> report = new HashMap<>();
        
        // Obtener fecha actual - AQUÍ TAMBIÉN ESTÁ EL PROBLEMA
        LocalDateTime now = LocalDateTime.now(ZoneId.of("UTC")); // Debería ser America/Mexico_City
        LocalDateTime startOfDay = now.toLocalDate().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1).minusNanos(1);
        
        // Convertir a Date para MongoDB
        Date start = Date.from(startOfDay.atZone(ZoneId.systemDefault()).toInstant());
        Date end = Date.from(endOfDay.atZone(ZoneId.systemDefault()).toInstant());
        
        MongoCollection<Document> billings = database.getCollection("billings");
        
        long count = billings.countDocuments(
            new Document("billingDate", 
                new Document("$gte", start).append("$lte", end))
        );
        
        report.put("date", now.format(DateTimeFormatter.ISO_LOCAL_DATE));
        report.put("totalBillings", count);
        report.put("status", count > 0 ? "normal" : "warning");
        report.put("message", count > 0 ? "Billing data found" : "No billing data found for today");
        
        return report;
    }
    
    public static void main(String[] args) {
        SpringApplication.run(ReportApplication.class, args);
    }
}
EOF

cd ..

# === NOTIFICATION SERVICE (Go) ===
echo "🐹 Creando notification service..."
cd notification-service

cat > go.mod << 'EOF'
module hospital-notifications

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    go.mongodb.org/mongo-driver v1.12.1
)
EOF

cat > main.go << 'EOF'
package main

import (
    "context"
    "log"
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
    "go.mongodb.org/mongo-driver/bson"
)

type NotificationService struct {
    client *mongo.Client
    db     *mongo.Database
}

func NewNotificationService() *NotificationService {
    client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI("mongodb://localhost:27017"))
    if err != nil {
        log.Fatal(err)
    }
    
    return &NotificationService{
        client: client,
        db:     client.Database("hospital_billing"),
    }
}

func (ns *NotificationService) CheckDailyBillings() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Otro lugar donde está el problema de timezone
        now := time.Now().UTC() // Debería ser time.Now().In(time.LoadLocation("America/Mexico_City"))
        startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
        endOfDay := startOfDay.Add(24 * time.Hour).Add(-time.Nanosecond)
        
        collection := ns.db.Collection("billings")
        
        count, err := collection.CountDocuments(context.TODO(), bson.M{
            "billingDate": bson.M{
                "$gte": startOfDay,
                "$lte": endOfDay,
            },
        })
        
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        
        status := "normal"
        message := "Billing data looks good"
        
        if count == 0 {
            status = "warning"
            message = "No billing data found for today - this might be a problem"
            log.Printf("⚠️ WARNING: No billing data found for %s", startOfDay.Format("2006-01-02"))
        }
        
        c.JSON(http.StatusOK, gin.H{
            "date":    startOfDay.Format("2006-01-02"),
            "count":   count,
            "status":  status,
            "message": message,
        })
    }
}

func main() {
    ns := NewNotificationService()
    defer ns.client.Disconnect(context.TODO())
    
    r := gin.Default()
    r.GET("/notifications/daily-check", ns.CheckDailyBillings())
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "healthy"})
    })
    
    log.Println("🔔 Notification service starting on :8080")
    r.Run(":8080")
}
EOF

cd ..

# === LEGACY BRIDGE (PHP) ===
echo "🐘 Creando legacy bridge..."
cd legacy-bridge

cat > composer.json << 'EOF'
{
    "name": "vitaltrack/legacy-bridge",
    "description": "Bridge to legacy hospital systems",
    "type": "project",
    "require": {
        "php": "^8.1",
        "mongodb/mongodb": "^1.15"
    },
    "autoload": {
        "psr-4": {
            "VitalTrack\\": "src/"
        }
    }
}
EOF

cat > index.php << 'EOF'
<?php
require_once 'vendor/autoload.php';

use MongoDB\Client;
use MongoDB\BSON\UTCDateTime;

class LegacyBridge {
    private $mongodb;
    
    public function __construct() {
        $this->mongodb = new Client("mongodb://localhost:27017");
    }
    
    public function getTodayBillings() {
        // Otro lugar con el problema de timezone
        $timezone = new DateTimeZone('UTC'); // Debería ser 'America/Mexico_City'
        $now = new DateTime('now', $timezone);
        
        $startOfDay = clone $now;
        $startOfDay->setTime(0, 0, 0);
        
        $endOfDay = clone $now;
        $endOfDay->setTime(23, 59, 59);
        
        $collection = $this->mongodb->hospital_billing->billings;
        
        $billings = $collection->find([
            'billingDate' => [
                '$gte' => new UTCDateTime($startOfDay),
                '$lte' => new UTCDateTime($endOfDay)
            ]
        ]);
        
        $results = [];
        foreach ($billings as $billing) {
            $results[] = [
                'patientId' => $billing['patientId'],
                'amount' => $billing['amount'],
                'date' => $billing['billingDate']->toDateTime()->format('Y-m-d H:i:s')
            ];
        }
        
        return $results;
    }
}

// API endpoint
if ($_SERVER['REQUEST_METHOD'] === 'GET' && $_SERVER['REQUEST_URI'] === '/legacy/today-billings') {
    header('Content-Type: application/json');
    
    $bridge = new LegacyBridge();
    $billings = $bridge->getTodayBillings();
    
    echo json_encode([
        'count' => count($billings),
        'billings' => $billings,
        'message' => count($billings) === 0 ? 'No billings found for today' : 'Billings retrieved successfully'
    ]);
} else {
    header('HTTP/1.1 404 Not Found');
    echo json_encode(['error' => 'Endpoint not found']);
}
?>
EOF

cd ..

# === SCRIPT PARA CREAR MÁS COMMITS CONFUSOS ===
cat > scripts/create_confusion.sh << 'EOF'
#!/bin/bash

# Script para crear más confusión en el historial

echo "🌪️ Creando más confusión en el historial..."

# Crear una rama con un fix que parece ser la solución pero no lo es
git checkout -b hotfix/billing-query-optimization

# Modificar una query que NO es la problemática
cat > backend/queries.js << 'QUERY_EOF'
// Optimización de queries de billing
const mongoose = require('mongoose');

// Esta query PARECE sospechosa pero no es el problema
const getBillingsByDateRange = async (startDate, endDate) => {
    try {
        // Query optimizada (pero no soluciona el problema real)
        const billings = await Billing.aggregate([
            {
                $match: {
                    billingDate: {
                        $gte: new Date(startDate),
                        $lte: new Date(endDate)
                    }
                }
            },
            {
                $sort: { billingDate: -1 }
            }
        ]);
        
        return billings;
    } catch (error) {
        console.error('Error in billing query:', error);
        throw error;
    }
};

module.exports = { getBillingsByDateRange };
QUERY_EOF

git add backend/queries.js
git commit -m "HOTFIX: Optimize billing date range queries - should fix empty results issue" --date="2024-03-18"

# Volver a main y NO hacer merge (pista falsa)
git checkout main

# Crear más commits de ruido con palabras clave que confundan
echo "// Performance improvement" >> backend/performance.js
git add backend/performance.js  
git commit -m "Performance: Fix slow date queries in billing module" --date="2024-03-19"

echo "// Timezone handling" >> backend/utils.js
git add backend/utils.js
git commit -m "Utils: Add timezone helper functions" --date="2024-03-19"

# Commit que parece ser un revert pero no lo es
echo "// Fake revert" >> backend/fake.js
git add backend/fake.js
git commit -m "Revert: billing date range changes causing issues" --date="2024-03-19"

echo "✅ Confusión adicional creada"
EOF

chmod +x scripts/create_confusion.sh

# === ARCHIVO DE SOLUCIÓN (PARA EL PROFESOR) ===
cat > SOLUTION.md << 'EOF'
# 🔍 SOLUCIÓN: El Detective del Código

## ⚠️ ARCHIVO SOLO PARA EL INSTRUCTOR

### El Problema Real

El bug está en la actualización de `moment-timezone` de la versión `0.5.34` a `0.5.43`.

### Ubicación del Bug

**Archivo**: `backend/server.js` líneas 32-33
**Commit**: "Security update: bump moment-timezone to fix vulnerability CVE-2024-XXXX"

```javascript
// ANTES (funcionaba):
const startOfDay = moment().startOf('day').toDate(); // Usaba timezone local

// DESPUÉS (roto):  
const startOfDay = moment().startOf('day').toDate(); // Ahora usa UTC por default
```

### ¿Por qué pasó?

La versión 0.5.43 de moment-timezone cambió el comportamiento default para usar UTC en lugar del timezone del sistema cuando no se especifica explícitamente.

### Cómo encontrarlo

```bash
# 1. Buscar cambios relacionados con fechas/timezone
git log -p --all | grep -A10 -B10 "timezone\|moment"

# 2. Comparar package-lock.json entre commits
git show HEAD~47:backend/package-lock.json | grep -A5 "moment-timezone"
git show HEAD~48:backend/package-lock.json | grep -A5 "moment-timezone"

# 3. Ver el diff específico del commit problemático
git show <commit-hash-del-security-update>
```

### La Solución

```javascript
// Cambiar en backend/server.js:
const startOfDay = moment().tz(HOSPITAL_TIMEZONE).startOf('day').toDate();
const endOfDay = moment().tz(HOSPITAL_TIMEZONE).endOf('day').toDate();
```

### Por qué era tan difícil encontrar

1. **Oculto entre 200+ commits** de ruido
2. **Los tests pasaban** (mal escritos)
3. **No había errores** en logs
4. **Múltiples pistas falsas** en diferentes servicios
5. **El cambio parecía insignificante** (actualización de dependencia)
6. **Funcionaba en desarrollo** (diferentes timezones)

### Prevención

1. **Tests de integración** que validen datos reales
2. **Documentar breaking changes** en dependencias
3. **Staging con datos reales** de producción
4. **Monitoreo de métricas de negocio**
5. **Code review** de actualizaciones de dependencias

### Tiempo Esperado de Resolución

- **Excelente**: 2-3 horas
- **Bueno**: 3-4 horas  
- **Suficiente**: 4+ horas (identificar área)

¡Este es exactamente el tipo de bug que atormentaría a un equipo real por días! 😅
EOF

# Ejecutar script de confusión adicional
bash scripts/create_confusion.sh

echo ""
echo "🎭 Archivos adicionales creados exitosamente"
echo ""
echo "📁 Estructura completa:"
echo "   ├── backend/ (Node.js con el bug)"
echo "   ├── frontend/ (React)"  
echo "   ├── data-processor/ (Python)"
echo "   ├── report-engine/ (Java)"
echo "   ├── notification-service/ (Go)"
echo "   ├── legacy-bridge/ (PHP)"
echo "   ├── deployment/ (Scripts y logs)"
echo "   ├── logs/ (Logs falsos)"
echo "   ├── tests/ (Tests que no detectan el bug)"
echo "   └── scripts/ (Herramientas de setup)"
echo ""
echo "🐛 El bug está replicado en MÚLTIPLES servicios"
echo "🕵️ Pero la solución real está en backend/server.js"
echo ""
echo "🎯 Para probar el examen:"
echo "   docker-compose up -d"
echo "   curl http://localhost:3000/api/billing/today"
echo "   # Debería devolver [] (vacío)"
echo ""
echo "✨ ¡El examen más legendario está listo!"
