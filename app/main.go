package main

import (
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

func main() {
	server := gin.Default()
	server.GET("", getEnvs)
	server.GET("/status", getStatus)
	err := server.Run(":8080")
	if err != nil {
		log.Fatalln(err)
	}
}

func getEnvs(context *gin.Context) {
	envSlice := os.Environ()
	envMap := make(map[string]string, len(envSlice))
	for _, record := range envSlice {
		key := strings.Split(record, "=")[0]
		value := strings.Split(record, "=")[1]
		envMap[key] = value
	}
	context.JSON(http.StatusOK, envMap)
}

func getStatus(context *gin.Context) {
	status := map[string]string{"status": "ok"}
	context.JSON(http.StatusOK, status)
}
