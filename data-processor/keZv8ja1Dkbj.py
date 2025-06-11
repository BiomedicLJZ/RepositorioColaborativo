#!/usr/bin/env python3
import pandas as pd
import pymongo
from datetime import datetime, timedelta
import pytz
import os
import logging

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BillingProcessor:
    def __init__(self):
        self.mongo_client = pymongo.MongoClient(
            os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
        )
        self.db = self.mongo_client.hospital_billing
        self.timezone = pytz.timezone(os.getenv('TIMEZONE', 'America/Mexico_City'))
    
    def process_daily_billing(self):
        """Procesa las facturas del día actual"""
        try:
            # Obtener fecha actual en timezone local
            now = datetime.now(self.timezone)
            start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
            end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=999999)
            
            logger.info(f"Procesando facturas entre {start_of_day} y {end_of_day}")
            
            # Buscar facturas del día
            billings = list(self.db.billings.find({
                'billingDate': {
                    '$gte': start_of_day.replace(tzinfo=None),  # MongoDB no maneja timezone
                    '$lte': end_of_day.replace(tzinfo=None)
                }
            }))
            
            logger.info(f"Encontradas {len(billings)} facturas para procesar")
            
            if not billings:
                logger.warning("⚠️ No se encontraron facturas para hoy - esto es inusual")
                return
            
            # Convertir a DataFrame para procesamiento
            df = pd.DataFrame(billings)
            
            # Procesar estadísticas
            total_amount = df['amount'].sum()
            avg_amount = df['amount'].mean()
            
            logger.info(f"💰 Total facturado hoy: ${total_amount:.2f}")
            logger.info(f"📊 Promedio por factura: ${avg_amount:.2f}")
            
            # Generar reporte
            self.generate_daily_report(df, now.date())
            
        except Exception as e:
            logger.error(f"Error procesando facturas: {e}")
    
    def generate_daily_report(self, df, date):
        """Genera reporte diario"""
        report = {
            'date': date.isoformat(),
            'total_billings': len(df),
            'total_amount': float(df['amount'].sum()),
            'avg_amount': float(df['amount'].mean()),
            'generated_at': datetime.now(self.timezone).isoformat()
        }
        
        # Guardar reporte
        self.db.daily_reports.insert_one(report)
        logger.info(f"📝 Reporte diario guardado para {date}")

if __name__ == "__main__":
    processor = BillingProcessor()
    processor.process_daily_billing()
