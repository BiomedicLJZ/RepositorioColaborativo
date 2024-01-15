import React, { useState, useEffect } from 'react';
import axios from 'axios';
import moment from 'moment';

function App() {
  const [billings, setBillings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTodayBillings();
  }, []);

  const fetchTodayBillings = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/billing/today');
      setBillings(response.data);
      setError(null);
    } catch (err) {
      setError('Error fetching billings');
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{padding: '20px'}}>
      <h1>🏥 Hospital Billing System</h1>
      <h2>Facturas de Hoy - {moment().format('YYYY-MM-DD')}</h2>
      
      {loading && <p>Cargando facturas...</p>}
      {error && <p style={{color: 'red'}}>{error}</p>}
      
      {!loading && !error && (
        <div>
          <p><strong>Total de facturas encontradas: {billings.length}</strong></p>
          {billings.length === 0 ? (
            <div style={{background: '#ffebee', padding: '20px', borderRadius: '4px'}}>
              <h3>⚠️ No hay facturas para hoy</h3>
              <p>Esto es extraño... deberían haber facturas.</p>
            </div>
          ) : (
            <ul>
              {billings.map(billing => (
                <li key={billing._id}>
                  Paciente: {billing.patientId} - 
                  Monto: ${billing.amount} - 
                  Fecha: {moment(billing.billingDate).format('YYYY-MM-DD HH:mm')}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
      
      <button onClick={fetchTodayBillings} style={{marginTop: '20px'}}>
        🔄 Actualizar
      </button>
    </div>
  );
}

export default App;
