package main

import (
    "context"
    "log"
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
    "go.mongodb.org/mongo-driver/bson"
)

type NotificationService struct {
    client *mongo.Client
    db     *mongo.Database
}

func NewNotificationService() *NotificationService {
    client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI("mongodb://localhost:27017"))
    if err != nil {
        log.Fatal(err)
    }
    
    return &NotificationService{
        client: client,
        db:     client.Database("hospital_billing"),
    }
}

func (ns *NotificationService) CheckDailyBillings() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Otro lugar donde está el problema de timezone
        now := time.Now().UTC() // Debería ser time.Now().In(time.LoadLocation("America/Mexico_City"))
        startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
        endOfDay := startOfDay.Add(24 * time.Hour).Add(-time.Nanosecond)
        
        collection := ns.db.Collection("billings")
        
        count, err := collection.CountDocuments(context.TODO(), bson.M{
            "billingDate": bson.M{
                "$gte": startOfDay,
                "$lte": endOfDay,
            },
        })
        
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        
        status := "normal"
        message := "Billing data looks good"
        
        if count == 0 {
            status = "warning"
            message = "No billing data found for today - this might be a problem"
            log.Printf("⚠️ WARNING: No billing data found for %s", startOfDay.Format("2006-01-02"))
        }
        
        c.JSON(http.StatusOK, gin.H{
            "date":    startOfDay.Format("2006-01-02"),
            "count":   count,
            "status":  status,
            "message": message,
        })
    }
}

func main() {
    ns := NewNotificationService()
    defer ns.client.Disconnect(context.TODO())
    
    r := gin.Default()
    r.GET("/notifications/daily-check", ns.CheckDailyBillings())
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "healthy"})
    })
    
    log.Println("🔔 Notification service starting on :8080")
    r.Run(":8080")
}
