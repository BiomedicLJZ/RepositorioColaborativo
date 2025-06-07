const express = require('express');
const moment = require('moment-timezone');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de timezone - AQUÍ ESTÁ EL PROBLEMA OCULTO
const HOSPITAL_TIMEZONE = process.env.TIMEZONE || 'America/Mexico_City';

// Middleware
app.use(express.json());
app.use(require('cors')());

// Conexión a MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hospital_billing');

// Modelo de Factura
const BillingSchema = new mongoose.Schema({
    patientId: String,
    amount: Number,
    services: [String],
    createdAt: { type: Date, default: Date.now },
    billingDate: Date,
    status: { type: String, default: 'pending' }
});

const Billing = mongoose.model('Billing', BillingSchema);

// RUTA PROBLEMÁTICA - La función que causa el bug
app.get('/api/billing/today', async (req, res) => {
    try {
        // Esta línea cambió comportamiento con la actualización de moment-timezone
        // Antes: respetaba timezone local
        // Después: usa UTC por default
        const startOfDay = moment().startOf('day').toDate();
        const endOfDay = moment().endOf('day').toDate();
        
        console.log(`Buscando facturas entre ${startOfDay} y ${endOfDay}`);
        
        const billings = await Billing.find({
            billingDate: {
                $gte: startOfDay,
                $lte: endOfDay
            }
        });
        
        console.log(`Encontradas ${billings.length} facturas`);
        res.json(billings);
    } catch (error) {
        console.error('Error fetching today billings:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Ruta para crear factura de prueba
app.post('/api/billing', async (req, res) => {
    try {
        const billing = new Billing({
            ...req.body,
            billingDate: new Date() // Usa fecha actual
        });
        await billing.save();
        res.status(201).json(billing);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Ruta de salud
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        timezone: HOSPITAL_TIMEZONE 
    });
});

app.listen(PORT, () => {
    console.log(`🏥 Hospital Billing Server running on port ${PORT}`);
    console.log(`🌍 Timezone: ${HOSPITAL_TIMEZONE}`);
});

// Random comment added by chaos gremlin at Sat Jun  7 13:37:11 CST 2025
