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
