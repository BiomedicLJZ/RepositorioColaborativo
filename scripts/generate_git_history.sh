#!/bin/bash

# Script para generar un historial Git complejo y confuso
echo "🕵️ Generando historial Git complejo..."

# Función para crear commits de ruido
create_noise_commits() {
    local count=$1
    local prefix=$2
    
    for i in $(seq 1 $count); do
        echo "// Noise commit $i" >> temp_file_$i.txt
        git add temp_file_$i.txt
        git commit -m "$prefix $i" --date="$(date -d "$((RANDOM % 30)) days ago" 2>/dev/null || date -v-${RANDOM}d 2>/dev/null || date)"
    done
    
    rm -f temp_file_*.txt
}

# Commits iniciales del proyecto
git add .
git commit -m "Initial project setup" --date="2024-01-15" 2>/dev/null || git commit -m "Initial project setup"

# Crear múltiples ramas para simular desarrollo paralelo
git checkout -b feature/billing-reports
echo "// Billing reports feature" >> backend/reports.js
git add backend/reports.js
git commit -m "Add billing reports functionality" --date="2024-02-01" 2>/dev/null || git commit -m "Add billing reports functionality"

git checkout -b feature/user-management  
echo "// User management" >> backend/auth.js
git add backend/auth.js
git commit -m "Implement user authentication" --date="2024-02-05" 2>/dev/null || git commit -m "Implement user authentication"

git checkout -b hotfix/security-patch
echo "// Security patch" >> backend/security.js
git add backend/security.js
git commit -m "Critical security patch" --date="2024-02-10" 2>/dev/null || git commit -m "Critical security patch"

# Volver a main y hacer merges conflictivos
git checkout main

# Simular muchos commits de dependencias
for i in {1..20}; do
    echo "Updated dependency $i" >> package-updates.log
    git add package-updates.log
    git commit -m "bump dependencies" --date="$(date -d "$((RANDOM % 60)) days ago" 2>/dev/null || date -v-${RANDOM}d 2>/dev/null || date)" 2>/dev/null || git commit -m "bump dependencies"
done

# El commit que introduce el bug (oculto entre el ruido)
# Simular actualización de package-lock.json
cat > backend/package-lock.json << 'LOCK_EOF'
{
  "name": "hospital-billing-backend",
  "version": "2.4.7",
  "lockfileVersion": 2,
  "requires": true,
  "packages": {
    "": {
      "name": "hospital-billing-backend",
      "version": "2.4.7"
    },
    "node_modules/moment-timezone": {
      "version": "0.5.43",
      "resolved": "https://registry.npmjs.org/moment-timezone/-/moment-timezone-0.5.43.tgz",
      "integrity": "sha512-72j3ux2VF8VQXJAQBc4T0D8XD+MQPu68m8mRjVHbNMHOLF0E0mKF2YOQZhqGOv8hbzPQFJPWnKdLPe8mh9xsqw==",
      "dependencies": {
        "moment": ">= 2.9.0"
      }
    }
  }
}
LOCK_EOF

# Actualizar package.json para mostrar la versión nueva
sed -i.bak 's/"moment-timezone": "\^0.5.34"/"moment-timezone": "^0.5.43"/' backend/package.json
rm -f backend/package.json.bak

git add backend/package.json backend/package-lock.json
git commit -m "Security update: bump moment-timezone to fix vulnerability CVE-2024-XXXX" --date="2024-03-15" 2>/dev/null || git commit -m "Security update: bump moment-timezone to fix vulnerability CVE-2024-XXXX"

# Más commits de ruido después del bug
create_noise_commits 30 "fix linting issue"
create_noise_commits 15 "update tests"
create_noise_commits 8 "fix typo"

# Commits recientes para despistar
echo "# Hospital Billing System" > README_temp.md
git add README_temp.md
git commit -m "Fix typo in README" --date="2024-03-20" 2>/dev/null || git commit -m "Fix typo in README"
rm -f README_temp.md

echo "✅ Historial Git complejo generado"
echo "🐛 El bug está oculto en el commit de actualización de moment-timezone"
