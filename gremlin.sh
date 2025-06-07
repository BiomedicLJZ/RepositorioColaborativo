#!/bin/bash

###############################################################################
# GIT CHAOS GREMLIN - Script de Caos Controlado para Repositorios Git
# ADVERTENCIA: Este script creará un desorden masivo en el repositorio
# Úsalo solo en repositorios de prueba o con respaldo completo
#
# USO:
#   ./git_chaos_gremlin.sh [NIVEL_CAOS] [PUSH_REMOTO]
#
# EJEMPLOS:
#   ./git_chaos_gremlin.sh                    # Nivel 3, solo local
#   ./git_chaos_gremlin.sh 5                  # Nivel 5, solo local  
#   ./git_chaos_gremlin.sh 4 true             # Nivel 4, con push remoto
#   ./git_chaos_gremlin.sh 3 true             # Nivel 3, con push remoto
#
# MODO EDUCATIVO:
#   Perfecto para crear repositorios de práctica donde los estudiantes
#   deben rescatar el código del caos absoluto usando sus habilidades Git
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RAINBOW='\033[1;35m'
NC='\033[0m' # No Color

# Configuración del caos
CHAOS_LEVEL=${1:-3}  # Nivel de caos (1-5, default 3)
TOTAL_COMMITS=150
TOTAL_BRANCHES=25
TOTAL_FILES_TO_DELETE=10
MERGE_CONFLICTS_TARGET=8
PUSH_TO_REMOTE=${2:-false}  # Si se debe hacer push al remoto

echo -e "${RED}🔥 INICIANDO GIT CHAOS GREMLIN 🔥${NC}"
echo -e "${YELLOW}Nivel de caos: $CHAOS_LEVEL/5${NC}"
echo -e "${YELLOW}Commits basura: $TOTAL_COMMITS${NC}"
echo -e "${YELLOW}Branches inútiles: $TOTAL_BRANCHES${NC}"
if [ "$PUSH_TO_REMOTE" = "true" ]; then
    echo -e "${RED}🚀 Modo: PUSH TO REMOTE ACTIVADO${NC}"
fi

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ No estás en un repositorio Git${NC}"
    exit 1
fi

# Verificar configuración de remoto si se va a hacer push
REMOTE_URL=""
HAS_REMOTE=false
if [ "$PUSH_TO_REMOTE" = "true" ]; then
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ -z "$REMOTE_URL" ]; then
        echo -e "${YELLOW}⚠️  No hay remoto configurado. ¿Quieres configurar uno ahora?${NC}"
        read -p "Introduce la URL del repositorio remoto (o presiona Enter para continuar sin push): " new_remote_url
        if [ -n "$new_remote_url" ]; then
            git remote add origin "$new_remote_url"
            REMOTE_URL="$new_remote_url"
            HAS_REMOTE=true
            echo -e "${GREEN}✅ Remoto configurado: $REMOTE_URL${NC}"
        else
            PUSH_TO_REMOTE="false"
            echo -e "${YELLOW}⚠️  Continuando sin push remoto${NC}"
        fi
    else
        HAS_REMOTE=true
        echo -e "${GREEN}📡 Remoto detectado: $REMOTE_URL${NC}"
    fi
fi

# Confirmación de seguridad
read -p "⚠️  ¿ESTÁS SEGURO? Esto creará caos absoluto en este repo (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Operación cancelada. Repo a salvo... por ahora 😈${NC}"
    exit 1
fi

if [ "$PUSH_TO_REMOTE" = "true" ] && [ "$HAS_REMOTE" = "true" ]; then
    echo -e "${RED}⚠️  ADVERTENCIA FINAL: Esto hará PUSH FORCE al repositorio remoto!${NC}"
    echo -e "${RED}    Los estudiantes verán este caos cuando hagan clone/pull${NC}"
    read -p "¿Continuar con push force? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        PUSH_TO_REMOTE="false"
        echo -e "${YELLOW}Continuando solo con caos local${NC}"
    fi
fi

echo -e "${RED}🎭 ¡EL CAOS COMIENZA!${NC}"

###############################################################################
# FUNCIÓN: Mensajes de commit inútiles
###############################################################################
generate_useless_commit_message() {
    local messages=(
        "fix stuff"
        "it works now"
        "???"
        "asdfghjkl"
        "commit"
        "changes"
        "update"
        "fix fix fix"
        "probably works"
        "YOLO commit"
        "not sure what this does"
        "magic"
        "¯\\\_(ツ)_/¯"
        "todo: fix this later"
        "oops"
        "final version"
        "final version 2"
        "final version FINAL"
        "actually final"
        "I hate git"
        "why does this exist"
        "commit before weekend"
        "drunk commit"
        "3am coding session"
        "stackoverflow copy paste"
        "please work"
        "crosses fingers"
        "send help"
        "code review? what's that?"
        "works on my machine"
        "deploy on friday"
        "legacy code is fun"
        "refactor TODO"
        "temporary hack"
        "will fix later (narrator: they never did)"
        "batman was here"
        "commit message goes here"
        "updated readme (not really)"
        "fixed typo (created 3 more)"
        "optimization (made it slower)"
        "security fix (removed authentication)"
        "added tests (they all fail)"
    )
    echo "${messages[$RANDOM % ${#messages[@]}]}"
}

###############################################################################
# FUNCIÓN: Nombres de branches absurdos
###############################################################################
generate_branch_name() {
    local prefixes=("feature" "bugfix" "hotfix" "experiment" "hack" "temp" "test" "dev" "prod" "staging")
    local suffixes=("chaos" "madness" "confusion" "disaster" "nightmare" "broken" "wtf" "help" "panic" "doom")
    local random_stuff=("123" "final" "backup" "old" "new" "copy" "real" "fake" "maybe" "idk")
    
    echo "${prefixes[$RANDOM % ${#prefixes[@]}]}-${suffixes[$RANDOM % ${#suffixes[@]}]}-${random_stuff[$RANDOM % ${#random_stuff[@]}]}"
}

###############################################################################
# FUNCIÓN: Crear archivos basura
###############################################################################
create_garbage_file() {
    local filename="garbage_$(date +%s)_$RANDOM"
    local extensions=(".txt" ".log" ".bak" ".tmp" ".old" ".copy" ".backup" ".test")
    local ext="${extensions[$RANDOM % ${#extensions[@]}]}"
    
    # Contenido aleatorio
    local content="This is garbage file created at $(date)\n"
    content+="Random data: $(openssl rand -hex 20)\n"
    content+="TODO: Delete this file\n"
    content+="Why does this exist???\n"
    
    echo -e "$content" > "${filename}${ext}"
    echo "${filename}${ext}"
}

###############################################################################
# FUNCIÓN: Crear .gitignore contradictorio
###############################################################################
create_contradictory_gitignore() {
    cat > .gitignore << EOF
# Ignore everything
*

# But not everything
!*

# Ignore logs
*.log
# But include this specific log
!important.log
# Actually ignore it
important.log

# Node modules
node_modules/
# Just kidding, include it
!node_modules/
# No wait, ignore it
node_modules/

# Ignore .env files (security!)
.env
# But include .env.example
!.env.example
# Include all .env files actually
!.env*
# No, ignore them all
.env*

# Ignore build directory
build/
dist/
# Include build directory
!build/
!dist/

# This makes no sense
*.txt
!*.txt
*.txt

# Ignore itself
.gitignore
# Include itself
!.gitignore
EOF
    echo -e "${PURPLE}📝 Creado .gitignore contradictorio${NC}"
}

###############################################################################
# FASE 1: COMMITS BASURA MASIVOS
###############################################################################
echo -e "\n${BLUE}🗑️  FASE 1: Generando commits basura...${NC}"

for i in $(seq 1 $TOTAL_COMMITS); do
    # Crear archivo basura ocasionalmente
    if [ $((RANDOM % 5)) -eq 0 ]; then
        garbage_file=$(create_garbage_file)
        git add "$garbage_file"
    fi
    
    # Modificar archivos existentes aleatoriamente
    if [ $((RANDOM % 3)) -eq 0 ]; then
        # Encontrar archivos existentes y modificarlos
        existing_files=($(find . -name "*.txt" -o -name "*.md" -o -name "*.js" -o -name "*.py" | head -5))
        if [ ${#existing_files[@]} -gt 0 ]; then
            random_file="${existing_files[$RANDOM % ${#existing_files[@]}]}"
            echo -e "\n// Random comment added by chaos gremlin at $(date)" >> "$random_file"
            git add "$random_file"
        fi
    fi
    
    # Crear commit vacío ocasionalmente
    if [ $((RANDOM % 7)) -eq 0 ]; then
        git commit --allow-empty -m "$(generate_useless_commit_message)"
    else
        git commit -m "$(generate_useless_commit_message)" 2>/dev/null || git commit --allow-empty -m "$(generate_useless_commit_message)"
    fi
    
    echo -ne "\rCommits creados: $i/$TOTAL_COMMITS"
done

echo -e "\n${GREEN}✅ $TOTAL_COMMITS commits basura creados${NC}"

###############################################################################
# FASE 2: CREAR BRANCHES CAÓTICOS
###############################################################################
echo -e "\n${BLUE}🌿 FASE 2: Creando branches caóticos...${NC}"

current_branch=$(git branch --show-current)
branches_created=()

for i in $(seq 1 $TOTAL_BRANCHES); do
    branch_name=$(generate_branch_name)
    git checkout -b "$branch_name" 2>/dev/null || git checkout -b "${branch_name}-${RANDOM}"
    branches_created+=("$branch_name")
    
    # Hacer algunos commits en cada branch
    for j in $(seq 1 $((RANDOM % 5 + 1))); do
        garbage_file=$(create_garbage_file)
        git add "$garbage_file"
        git commit -m "$(generate_useless_commit_message)"
    done
    
    echo -ne "\rBranches creados: $i/$TOTAL_BRANCHES"
done

echo -e "\n${GREEN}✅ $TOTAL_BRANCHES branches caóticos creados${NC}"

###############################################################################
# FASE 2.5: CREAR TELARAÑA DE MERGES CAÓTICOS - RAINBOW CHAOS WEB
###############################################################################
echo -e "\n${BLUE}🕷️🌈 FASE 2.5: Tejiendo telaraña de caos absoluto...${NC}"

git checkout "$current_branch"

# Crear red compleja de branches interconectados
spider_branches=("web-strand-1" "chaos-thread-alpha" "tangle-beta" "knot-gamma" "mess-delta" "spaghetti-main" "rainbow-bridge" "void-connector" "quantum-branch" "parallel-universe")

echo -e "${PURPLE}🕸️  Creando hilos de la telaraña...${NC}"

# FASE A: Crear branches base con commits mínimos
for spider_branch in "${spider_branches[@]}"; do
    git checkout "$current_branch"
    git checkout -b "$spider_branch"
    
    # Commits absolutamente inútiles pero necesarios para crear diversidad
    meaningless_file="meaningless_${spider_branch}_$(date +%s).txt"
    echo "This branch exists for no reason whatsoever" > "$meaningless_file"
    echo "Branch: $spider_branch" >> "$meaningless_file"
    echo "Purpose: None" >> "$meaningless_file"
    echo "Chaos level: Maximum" >> "$meaningless_file"
    git add "$meaningless_file"
    git commit -m "[$spider_branch] Initial meaningless commit"
    
    # Más commits sin sentido
    for j in $(seq 1 $((RANDOM % 3 + 1))); do
        echo "Random update #$j at $(date)" >> "$meaningless_file"
        git add "$meaningless_file"
        git commit -m "[$spider_branch] $(generate_useless_commit_message)"
    done
done

# FASE B: MERGES ENTRECRUZADOS MASIVOS - Aquí empieza el verdadero caos
echo -e "${RED}🌪️  Iniciando tornado de merges entrecruzados...${NC}"

all_spider_branches=("${spider_branches[@]}")
git checkout "$current_branch"

# Crear merges circulares y entrecruzados
for round in $(seq 1 4); do
    echo -e "${YELLOW}🔄 Ronda de caos #$round${NC}"
    
    # Shuffle las branches para crear caos impredecible
    shuffled_branches=($(printf '%s\n' "${all_spider_branches[@]}" | shuf))
    
    for i in $(seq 0 $((${#shuffled_branches[@]} - 2))); do
        branch_a="${shuffled_branches[$i]}"
        branch_b="${shuffled_branches[$((i + 1))]}"
        
        # Merge A -> B
        if git checkout "$branch_a" 2>/dev/null; then
            if git merge "$branch_b" --no-ff --no-edit -m "🕷️ Web merge: $branch_b into $branch_a (round $round)" 2>/dev/null; then
                echo -e "${GREEN}  ✓ $branch_b -> $branch_a${NC}"
            fi
            
            # Commit post-merge para más caos
            post_merge_file="post_merge_${branch_a}_${round}.txt"
            echo "Post-merge chaos in $branch_a after merging $branch_b" > "$post_merge_file"
            git add "$post_merge_file"
            git commit -m "[$branch_a] Post-merge chaos commit"
        fi
        
        # Merge inverso B -> A (crear ciclos)
        if [ $((RANDOM % 3)) -eq 0 ]; then
            if git checkout "$branch_b" 2>/dev/null; then
                if git merge "$branch_a" --no-ff --no-edit -m "🔄 Reverse web merge: $branch_a into $branch_b" 2>/dev/null; then
                    echo -e "${PURPLE}  ↩️ $branch_a -> $branch_b (reverse)${NC}"
                fi
            fi
        fi
    done
    
    # Merge random branches con main
    random_branch="${shuffled_branches[$((RANDOM % ${#shuffled_branches[@]}))]}"
    git checkout "$current_branch"
    if git merge "$random_branch" --no-ff --no-edit -m "🌈 Rainbow merge: $random_branch -> main (round $round)" 2>/dev/null; then
        echo -e "${BLUE}  🌈 $random_branch -> main${NC}"
    fi
done

# FASE C: CREAR BRANCHES TEMPORALES Y MERGES INSTANTÁNEOS
echo -e "${YELLOW}⚡ Creando branches temporales con merges instantáneos...${NC}"

for temp_round in $(seq 1 8); do
    temp_branch="temp-chaos-$temp_round-$(date +%s)"
    base_branch="${all_spider_branches[$((RANDOM % ${#all_spider_branches[@]}))]}"
    
    # Crear branch temporal desde branch aleatoria
    if git checkout "$base_branch" 2>/dev/null; then
        git checkout -b "$temp_branch"
        
        # Commit mínimo
        temp_file="temp_$temp_round.txt"
        echo "Temporary chaos $temp_round" > "$temp_file"
        git add "$temp_file"
        git commit -m "Temp branch $temp_branch with no purpose"
        
        # Merge inmediato con otra branch aleatoria
        target_branch="${all_spider_branches[$((RANDOM % ${#all_spider_branches[@]}))]}"
        if [ "$target_branch" != "$base_branch" ]; then
            if git checkout "$target_branch" 2>/dev/null; then
                if git merge "$temp_branch" --no-ff --no-edit -m "⚡ Instant merge: $temp_branch -> $target_branch" 2>/dev/null; then
                    echo -e "${YELLOW}  ⚡ $temp_branch -> $target_branch${NC}"
                fi
            fi
        fi
        
        # Agregar a la lista para más caos
        all_spider_branches+=("$temp_branch")
    fi
done

# FASE D: MERGES MASIVOS FINALES - EL GRAN FINALE
echo -e "${RED}🎆 GRAN FINALE: Merges masivos finales...${NC}"

git checkout "$current_branch"

# Crear branches "collector" que merge múltiples branches
collector_branches=("chaos-collector-1" "merge-monster" "spaghetti-collector")

for collector in "${collector_branches[@]}"; do
    git checkout "$current_branch"
    git checkout -b "$collector"
    
    # Este branch va a merge un montón de otros
    echo "Collector branch: $collector" > "collector_${collector}.txt"
    git add "collector_${collector}.txt"
    git commit -m "[$collector] Collector branch initialized"
    
    # Merge varios branches aleatorios
    for merge_count in $(seq 1 5); do
        random_victim="${all_spider_branches[$((RANDOM % ${#all_spider_branches[@]}))]}"
        if git merge "$random_victim" --no-ff --no-edit -m "🎯 [$collector] Collecting $random_victim (#$merge_count)" 2>/dev/null; then
            echo -e "${RED}  🎯 $random_victim -> $collector${NC}"
        fi
    done
    
    # Merge collector con main
    git checkout "$current_branch"
    if git merge "$collector" --no-ff --no-edit -m "🎆 FINALE: Merging collector $collector into main" 2>/dev/null; then
        echo -e "${RED}🎆 $collector -> main (FINALE)${NC}"
    fi
done

# FASE E: MERGES CRUZADOS FINALES ALEATORIOS
echo -e "${PURPLE}🌀 Merges cruzados finales aleatorios...${NC}"

# Hacer merges completamente aleatorios para maximizar el caos
for random_merge in $(seq 1 15); do
    branch1="${all_spider_branches[$((RANDOM % ${#all_spider_branches[@]}))]}"
    branch2="${all_spider_branches[$((RANDOM % ${#all_spider_branches[@]}))]}"
    
    if [ "$branch1" != "$branch2" ]; then
        if git checkout "$branch1" 2>/dev/null; then
            if git merge "$branch2" --no-ff --no-edit -m "🌀 Random chaos merge #$random_merge: $branch2 -> $branch1" 2>/dev/null; then
                echo -e "${PURPLE}  🌀 Random: $branch2 -> $branch1${NC}"
            fi
        fi
    fi
done

git checkout "$current_branch"
echo -e "${GREEN}✅ Telaraña de caos completada - El grafo ahora es puro arte abstracto${NC}"

###############################################################################
# FASE 3: MERGES PROBLEMÁTICOS
###############################################################################
echo -e "\n${BLUE}🔀 FASE 3: Creando merges problemáticos...${NC}"

git checkout "$current_branch"

# Algunos merges exitosos (forzando commits de merge)
successful_merges=0
for branch in "${branches_created[@]:0:10}"; do
    if git merge "$branch" --no-edit --no-ff 2>/dev/null; then
        ((successful_merges++))
        echo -e "${GREEN}✅ Merge exitoso: $branch${NC}"
    fi
done

# Crear conflictos intencionalmente
conflict_file="conflict_generator.txt"
echo "Original content" > "$conflict_file"
git add "$conflict_file"
git commit -m "Add conflict generator file"

# Crear branches que causarán conflictos
for i in $(seq 1 $MERGE_CONFLICTS_TARGET); do
    conflict_branch="conflict-branch-$i"
    git checkout -b "$conflict_branch"
    echo "Conflicting content from branch $i" > "$conflict_file"
    git add "$conflict_file"
    git commit -m "Modify conflict file in $conflict_branch"
    
    git checkout "$current_branch"
    echo "Different conflicting content $i" > "$conflict_file"
    git add "$conflict_file"
    git commit -m "Modify conflict file in main branch"
    
    # Intentar merge (fallará)
    if ! git merge "$conflict_branch" --no-edit --no-ff 2>/dev/null; then
        echo -e "${RED}💥 Conflicto creado con $conflict_branch${NC}"
        # Resolver conflicto de manera horrible
        echo "<<<<<<< HEAD
Different conflicting content $i
=======
Conflicting content from branch $i
>>>>>>> $conflict_branch
CHAOS GREMLIN WAS HERE" > "$conflict_file"
        git add "$conflict_file"
        git commit -m "Resolve conflict (badly)"
    fi
done

###############################################################################
# FASE 4: ELIMINAR ARCHIVOS IMPORTANTES (simulado)
###############################################################################
echo -e "\n${BLUE}🗑️  FASE 4: Creando archivos 'importantes' y eliminándolos...${NC}"

# Crear archivos que parecen importantes
important_files=("config.json" "database.sql" "secrets.env" "production.conf" "backup.tar.gz")

for file in "${important_files[@]}"; do
    echo "IMPORTANT DATA - DO NOT DELETE" > "$file"
    git add "$file"
    git commit -m "Add critical file: $file"
    
    # Eliminar el archivo en el siguiente commit
    rm "$file"
    git add "$file"
    git commit -m "Remove $file (oops)"
    
    echo -e "${RED}🗑️  Eliminado archivo 'importante': $file${NC}"
done

###############################################################################
# FASE 5: GITIGNORE CONTRADICTORIO Y TAGS CONFUSOS
###############################################################################
echo -e "\n${BLUE}📝 FASE 5: Creando .gitignore contradictorio y tags confusos...${NC}"

create_contradictory_gitignore
git add .gitignore
git commit -m "Add professional .gitignore"

# Tags confusos
confusing_tags=("v1.0.0" "v1.0.1" "v1.0.0-final" "v2.0.0-beta" "v1.0.0-really-final" "production-ready" "stable" "broken" "do-not-use")

for tag in "${confusing_tags[@]}"; do
    git tag "$tag" 2>/dev/null || git tag "${tag}-${RANDOM}"
done

echo -e "${GREEN}✅ Tags confusos creados${NC}"

###############################################################################
# FASE 7: PUSH FORCE AL REMOTO (MODO EDUCATIVO)
###############################################################################
if [ "$PUSH_TO_REMOTE" = "true" ] && [ "$HAS_REMOTE" = "true" ]; then
    echo -e "\n${RED}🚀 FASE 7: Enviando caos al repositorio remoto...${NC}"
    echo -e "${YELLOW}⚠️  Preparando push force - Los estudiantes van a sufrir... educativamente 😈${NC}"
    
    # Push de la rama principal con force
    echo -e "${BLUE}📤 Pushing rama principal...${NC}"
    if git push --force origin "$current_branch"; then
        echo -e "${GREEN}✅ Rama principal enviada con éxito${NC}"
    else
        echo -e "${RED}❌ Error enviando rama principal${NC}"
    fi
    
    # Push de todas las branches caóticas
    echo -e "${BLUE}📤 Pushing todas las branches caóticas...${NC}"
    all_branches=($(git branch | grep -v '\\*' | tr -d ' '))
    pushed_branches=0
    failed_branches=0
    
    for branch in "${all_branches[@]}"; do
        if git push --force origin "$branch" 2>/dev/null; then
            ((pushed_branches++))
            echo -ne "\r${GREEN}✅ Branches enviadas: $pushed_branches${NC}"
        else
            ((failed_branches++))
        fi
    done
    
    echo -e "\n${GREEN}📊 Resumen del push:${NC}"
    echo -e "${YELLOW}  - Branches enviadas exitosamente: $pushed_branches${NC}"
    echo -e "${YELLOW}  - Branches que fallaron: $failed_branches${NC}"
    
    # Push de tags
    echo -e "${BLUE}📤 Pushing tags...${NC}"
    if git push --force --tags origin; then
        echo -e "${GREEN}✅ Tags enviados${NC}"
    else
        echo -e "${YELLOW}⚠️  Algunos tags no se pudieron enviar${NC}"
    fi
    
    echo -e "\n${RED}🎓 REPOSITORIO REMOTO CONTAMINADO EXITOSAMENTE${NC}"
    echo -e "${PURPLE}   Los estudiantes ahora pueden clonar el caos con:${NC}"
    echo -e "${YELLOW}   git clone $REMOTE_URL${NC}"
    echo -e "${PURPLE}   ¡Que comiencen los juegos del hambre... digo, del Git! 🎮${NC}"
    
    # Instrucciones para estudiantes
    echo -e "\n${BLUE}📚 INSTRUCCIONES PARA COMPARTIR CON ESTUDIANTES:${NC}"
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  🎯 DESAFÍO GIT: RESCATA EL REPOSITORIO DEL CAOS ABSOLUTO    ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  1. git clone $REMOTE_URL${NC}"
    echo -e "${YELLOW}║  2. git log --graph --oneline --all  (para ver el desastre) ║${NC}"
    echo -e "${YELLOW}║  3. ¡Tu misión: limpiar este caos!                           ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  Objetivos sugeridos:                                       ║${NC}"
    echo -e "${YELLOW}║  • Crear una rama limpia desde un commit estable            ║${NC}"
    echo -e "${YELLOW}║  • Eliminar branches innecesarias                           ║${NC}"
    echo -e "${YELLOW}║  • Reescribir el historial (git rebase interactive)         ║${NC}"
    echo -e "${YELLOW}║  • Crear un historial lineal y comprensible                 ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  ¡Bonus: Explica qué salió mal y cómo prevenir este caos!   ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    
else
    echo -e "\n${BLUE}📋 MODO LOCAL: El caos se mantiene solo en este repositorio${NC}"
    echo -e "${YELLOW}   Para compartir con estudiantes posteriormente:${NC}"
    echo -e "${YELLOW}   1. Configura un remoto: git remote add origin <URL>${NC}"
    echo -e "${YELLOW}   2. Ejecuta: git push --force --all origin${NC}"
    echo -e "${YELLOW}   3. Ejecuta: git push --force --tags origin${NC}"
fi

###############################################################################
# FASE 6: ESTADÍSTICAS FINALES DEL CAOS
###############################################################################
echo -e "\n${RED}📊 ESTADÍSTICAS DEL CAOS GENERADO:${NC}"
echo -e "${YELLOW}Total de commits: $(git rev-list --count HEAD)${NC}"
echo -e "${YELLOW}Total de branches: $(git branch -a | wc -l)${NC}"
echo -e "${YELLOW}Total de tags: $(git tag | wc -l)${NC}"
echo -e "${YELLOW}Archivos en working directory: $(find . -type f | wc -l)${NC}"
echo -e "${YELLOW}Tamaño del repositorio: $(du -sh .git | cut -f1)${NC}"

echo -e "\n${RED}🎭 ¡CAOS COMPLETADO! 🎭${NC}"
echo -e "${PURPLE}El repositorio ahora es un hermoso desastre.${NC}"
echo -e "${PURPLE}¡Que tengas suerte limpiando esto! 😈${NC}"

# Mostrar el estado actual
echo -e "\n${RED}🎨 OBRA MAESTRA DE CAOS GENERADA:${NC}"
echo -e "${RAINBOW}
    ╔══════════════════════════════════════════════════════════════╗
    ║                    🌈 RAINBOW CHAOS WEB 🕷️                    ║
    ║              ¡Tu grafo ahora es arte abstracto!              ║
    ╚══════════════════════════════════════════════════════════════╝
${NC}"

echo -e "\n${BLUE}📈 Vista previa del grafo (primeras 20 líneas):${NC}"
git log --graph --oneline --all -20

echo -e "\n${YELLOW}🎯 COMANDOS PARA ADMIRAR TU OBRA DE ARTE:${NC}"
echo -e "${GREEN}   # El clásico - líneas simples${NC}"
echo -e "${YELLOW}   git log --graph --oneline --all${NC}"
echo -e ""
echo -e "${GREEN}   # Versión colorida y detallada${NC}"
echo -e "${YELLOW}   git log --graph --pretty=format:'%C(red)%h%C(reset) -%C(yellow)%d%C(reset) %s %C(green)(%cr) %C(bold blue)<%an>%C(reset)' --abbrev-commit --all${NC}"
echo -e ""
echo -e "${GREEN}   # Solo las últimas 50 líneas (recomendado para empezar)${NC}"
echo -e "${YELLOW}   git log --graph --oneline --all -50${NC}"
echo -e ""
echo -e "${GREEN}   # Versión ASCII art completa (prepárate para el scroll infinito)${NC}"
echo -e "${YELLOW}   git log --graph --all --format='%h %s'${NC}"

echo -e "\n${BLUE}🌿 Branches creados (muestra parcial):${NC}"
git branch -a | head -20
total_branches=$(git branch -a | wc -l)
echo -e "${PURPLE}   ... y $((total_branches - 20)) branches más! 🤯${NC}"

echo -e "\n${BLUE}🔍 Para ver el grafo completo usa:${NC}"
echo -e "${YELLOW}   git log --graph --oneline --all${NC}"
echo -e "${YELLOW}   git log --graph --pretty=format:'%h %d %s' --all${NC}"

echo -e "\n${YELLOW}💡 Para limpiar este desastre localmente:${NC}"
echo -e "${YELLOW}   git reset --hard HEAD~$TOTAL_COMMITS${NC}"
echo -e "${YELLOW}   git branch | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -D${NC}"
echo -e "${YELLOW}   git tag | xargs git tag -d${NC}"
echo -e "${YELLOW}   O mejor aún: rm -rf .git && git init 😅${NC}"

if [ "$PUSH_TO_REMOTE" = "true" ] && [ "$HAS_REMOTE" = "true" ]; then
    echo -e "\n${RED}🎓 MODO EDUCATIVO ACTIVADO:${NC}"
    echo -e "${GREEN}   ✅ Repositorio remoto contaminado exitosamente${NC}"
    echo -e "${GREEN}   ✅ Los estudiantes pueden clonar y practicar${NC}"
    echo -e "${GREEN}   ✅ Desafío Git listo para usar${NC}"
    echo -e "\n${BLUE}🔗 URL del repositorio: $REMOTE_URL${NC}"
    echo -e "${BLUE}📋 Comparte las instrucciones de arriba con tus estudiantes${NC}"
fi
