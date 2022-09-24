package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/dapr/go-sdk/service/common"
	daprd "github.com/dapr/go-sdk/service/grpc"
	"github.com/gin-gonic/gin"
)

type healthcheck struct {
	Message string `json:"message"`
}

var healthchecks = []healthcheck{
	{Message: "Go subscriber is healthy!"},
}

var sub = &common.Subscription{
	PubsubName: "planetpubsub",
	Topic:      "planets",
}

func main() {
	router := gin.Default()
	router.GET("/health", healthCheck)

	router.Run("0.0.0.0:8002")

	service, err := daprd.NewService(":50002")
	if err != nil {
		log.Fatalf("Failed to start the server: %v", err)
	}
	if err := service.AddTopicEventHandler(sub, eventHandler); err != nil {
		log.Fatalf("Error adding topic subscription: %v", err)
	}
	if err := service.Start(); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}

func eventHandler(ctx context.Context, e *common.TopicEvent) (retry bool, err error) {
	fmt.Printf("Event - PubsubName:%s, Topic:%s, ID:%s, Data: %v", e.PubsubName, e.Topic, e.ID, e.Data)
	return true, nil
}

func healthCheck(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, healthchecks)
}
