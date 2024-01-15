// Inicialización de MongoDB con datos de prueba
db = db.getSiblingDB('hospital_billing');

// Crear facturas de prueba con fechas de los últimos días
const now = new Date();
const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
const dayBefore = new Date(now.getTime() - 48 * 60 * 60 * 1000);

// Facturas de ayer (deberían aparecer si no hubiera bug)
db.billings.insertMany([
  {
    patientId: "P001",
    amount: 150.00,
    services: ["Consulta General", "Rayos X"],
    billingDate: yesterday,
    status: "pending"
  },
  {
    patientId: "P002", 
    amount: 300.50,
    services: ["Cirugía Menor"],
    billingDate: yesterday,
    status: "pending"
  },
  {
    patientId: "P003",
    amount: 75.25,
    services: ["Análisis de Sangre"],
    billingDate: dayBefore,
    status: "completed"
  }
]);

// Crear índices
db.billings.createIndex({ "billingDate": 1 });
db.billings.createIndex({ "patientId": 1 });

print("✅ Base de datos inicializada con datos de prueba");
