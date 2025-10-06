package main

import (
	"log"
	"net/http"
	"server/internal/database"
	"server/internal/game"
	"server/internal/network"
)

func main() {
	// Тестируем подключение к БД
	log.Println("Testing database connection...")
	repo := database.NewRepository()
	log.Println("✅ Database connection successful!")

	// Инициализируем менеджер игры с репозиторием
	gameManager := game.NewGameManager(repo)

	// Настраиваем WebSocket обработчик
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		network.HandleWebSocket(w, r, gameManager)
	})

	// Статические файлы для статусной страницы
	http.Handle("/", http.FileServer(http.Dir("./static")))

	log.Println("Server starting on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}