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
