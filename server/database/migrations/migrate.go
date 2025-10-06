package main

import (
    "database/sql"
    "log"
    "os"
    "server/config"
    "server/internal/database"  // ← НОВЫЙ ПУТЬ
    _ "github.com/lib/pq"
)

func main() {
	cfg := config.Load()
	
	db, err := sql.Open("postgres", cfg.GetDBConnectionString())
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Читаем файл схемы
	schema, err := os.ReadFile("database/migrations/schema.sql")
	if err != nil {
		log.Fatal("Failed to read schema file:", err)
	}

	// Выполняем миграции
	_, err = db.Exec(string(schema))
	if err != nil {
		log.Fatal("Failed to execute migrations:", err)
	}

	log.Println("✅ Database migrations completed successfully!")
}