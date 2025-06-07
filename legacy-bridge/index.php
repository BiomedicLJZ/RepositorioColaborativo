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
