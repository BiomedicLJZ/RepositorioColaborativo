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
