package network

import (
	"encoding/json"
	"log"
	"net/http"
	"server/types"
	"sync"

	"github.com/gorilla/websocket"
)

type WebSocketConnection struct {
	Conn *websocket.Conn
	mu   sync.Mutex
}

type MessageHandler interface {
	HandleLogin(conn *WebSocketConnection, playerID, playerName string)
	HandleAttack(conn *WebSocketConnection, monsterID string)
	HandleDisconnect(conn *WebSocketConnection)
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func (c *WebSocketConnection) Send(message types.ServerMessage) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	
	// Логируем отправляемое сообщение
	log.Printf("WebSocket sending message: %+v", message)
	
	data, err := json.Marshal(message)
	if err != nil {
		log.Printf("JSON marshal error: %v", err)
		return err
	}
	
	log.Printf("WebSocket sending raw JSON: %s", string(data))
	
	err = c.Conn.WriteMessage(websocket.TextMessage, data)
	if err != nil {
		log.Printf("WebSocket write error: %v", err)
		return err
	}
	
	log.Printf("WebSocket message sent successfully")
	return nil
}

func HandleWebSocket(w http.ResponseWriter, r *http.Request, handler MessageHandler) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	log.Println("New WebSocket connection")

	wsConn := &WebSocketConnection{Conn: conn}

	for {
		// Читаем сырые данные для отладки
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			handler.HandleDisconnect(wsConn)
			break
		}

		log.Printf("Received raw message: type=%d, data=%s", messageType, string(data))

		// Пытаемся распарсить JSON
		var msg types.ClientMessage
		if err := json.Unmarshal(data, &msg); err != nil {
			log.Printf("JSON parse error: %v", err)
			continue
		}

		log.Printf("Received parsed message: %s", msg.Type)
		handleMessage(wsConn, msg, handler)
	}
}

func handleMessage(conn *WebSocketConnection, msg types.ClientMessage, handler MessageHandler) {
    log.Printf("Received message type: %s, PlayerName: '%s', PlayerID: '%s'", msg.Type, msg.PlayerName, msg.PlayerID)
    
    switch msg.Type {
    case "login":
        playerID := msg.PlayerID
        playerName := msg.PlayerName
        
        log.Printf("Login data - ID: '%s', Name: '%s'", playerID, playerName)
        
        if playerName == "" {
            conn.Send(types.ServerMessage{
                Type:    "login",
                Success: false,
                Error:   "Player name is required",
            })
            return
        }
        
        handler.HandleLogin(conn, playerID, playerName)
        
    case "attack_monster":
        monsterID := msg.MonsterID
        handler.HandleAttack(conn, monsterID)
    }
}