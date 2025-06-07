package com.vitaltrack.reports;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import com.mongodb.client.*;
import org.bson.Document;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

@SpringBootApplication
@RestController
public class ReportApplication {
    
    private MongoClient mongoClient;
    private MongoDatabase database;
    
    public ReportApplication() {
        mongoClient = MongoClients.create("mongodb://localhost:27017");
        database = mongoClient.getDatabase("hospital_billing");
    }
    
    @GetMapping("/reports/daily")
    public Map<String, Object> getDailyReport() {
        Map<String, Object> report = new HashMap<>();
        
        // Obtener fecha actual - AQUÍ TAMBIÉN ESTÁ EL PROBLEMA
        LocalDateTime now = LocalDateTime.now(ZoneId.of("UTC")); // Debería ser America/Mexico_City
        LocalDateTime startOfDay = now.toLocalDate().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1).minusNanos(1);
        
        // Convertir a Date para MongoDB
        Date start = Date.from(startOfDay.atZone(ZoneId.systemDefault()).toInstant());
        Date end = Date.from(endOfDay.atZone(ZoneId.systemDefault()).toInstant());
        
        MongoCollection<Document> billings = database.getCollection("billings");
        
        long count = billings.countDocuments(
            new Document("billingDate", 
                new Document("$gte", start).append("$lte", end))
        );
        
        report.put("date", now.format(DateTimeFormatter.ISO_LOCAL_DATE));
        report.put("totalBillings", count);
        report.put("status", count > 0 ? "normal" : "warning");
        report.put("message", count > 0 ? "Billing data found" : "No billing data found for today");
        
        return report;
    }
    
    public static void main(String[] args) {
        SpringApplication.run(ReportApplication.class, args);
    }
}
