package server

import (
	"encoding/json"
	"fmt"
	"hook/game"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type WSMsg struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

type Room struct {
	Code    string
	Players map[string]*game.PlayerInfo
	Game    *game.Game
	Status  string
	mu      sync.Mutex
}

var rooms = make(map[string]*Room)
var roomsMu sync.Mutex

var upgrader = websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}

func ServeWS(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	// defer conn.Close() -> handled in loop or cleanup
	
	var room *Room
	var playerID string

	for {
		var msg WSMsg
		if err := conn.ReadJSON(&msg); err != nil {
			break
		}
		switch msg.Type {
		case "create_room":
			code := fmt.Sprintf("%06d", rand.Intn(999999))
			var data struct{ Name string `json:"name"`; AvatarID string `json:"avatar_id"` }
			json.Unmarshal(msg.Payload, &data)
			
			roomsMu.Lock()
			playerID = fmt.Sprintf("%d", time.Now().UnixNano())
			r := &Room{Code: code, Players: make(map[string]*game.PlayerInfo), Status: "waiting"}
			rooms[code] = r
			roomsMu.Unlock()

			r.mu.Lock()
			r.Players[playerID] = &game.PlayerInfo{ID: playerID, Name: data.Name, Team: game.TeamRadiant, Conn: conn, Color: game.RandomColor(), AvatarID: data.AvatarID}
			r.mu.Unlock()
			
			room = r
			conn.WriteJSON(map[string]interface{}{"type": "room_joined", "code": code, "id": playerID, "is_host": true})
			broadcastLobby(room)

		case "join_room":
			var data struct {
				Code     string `json:"code"`
				Name     string `json:"name"`
				AvatarID string `json:"avatar_id"`
			}
			json.Unmarshal(msg.Payload, &data)
			
			roomsMu.Lock()
			r, exists := rooms[data.Code]
			roomsMu.Unlock()

			if !exists {
				conn.WriteJSON(map[string]string{"type": "error", "message": "Invalid Room"})
				continue
			}
			
			r.mu.Lock()
			if r.Status != "waiting" {
				r.mu.Unlock()
				conn.WriteJSON(map[string]string{"type": "error", "message": "Game Already Started"})
				continue
			}
			playerID = fmt.Sprintf("%d", time.Now().UnixNano())
			r.Players[playerID] = &game.PlayerInfo{ID: playerID, Name: data.Name, Team: game.TeamDire, Conn: conn, Color: game.RandomColor(), AvatarID: data.AvatarID}
			r.mu.Unlock()

			room = r
			conn.WriteJSON(map[string]interface{}{"type": "room_joined", "code": data.Code, "id": playerID, "is_host": false})
			broadcastLobby(room)

		case "switch_team":
			if room != nil {
				room.mu.Lock()
				if p, ok := room.Players[playerID]; ok {
					if p.Team == game.TeamRadiant {
						p.Team = game.TeamDire
					} else {
						p.Team = game.TeamRadiant
					}
				}
				room.mu.Unlock()
				broadcastLobby(room)
			}

		case "change_avatar":
			if room != nil {
				var data struct{ AvatarID string `json:"avatar_id"` }
				json.Unmarshal(msg.Payload, &data)
				room.mu.Lock()
				if p, ok := room.Players[playerID]; ok {
					p.AvatarID = data.AvatarID
				}
				room.mu.Unlock()
				broadcastLobby(room)
			}

		case "start_game":
			if room != nil {
				room.mu.Lock()
				if room.Status == "waiting" {
					room.Status = "playing"
					room.Game = game.NewGame(room.Players)
					go runGameLoop(room)
					for _, p := range room.Players {
						p.Conn.WriteJSON(map[string]string{"type": "game_started"})
					}
				}
				room.mu.Unlock()
			}

		case "input":
			if room != nil && room.Game != nil {
				var input struct {
					Type     string
					SkillIdx int
					X, Y     float64
					TargetID string
				}
				json.Unmarshal(msg.Payload, &input)
				room.Game.HandleInput(playerID, input.Type, input.SkillIdx, input.X, input.Y, input.TargetID)
			}
		}
	}

	if room != nil {
		// Disconnect logic
		room.mu.Lock() // Fixed: Using r.mu
		delete(room.Players, playerID)
		isEmpty := len(room.Players) == 0
		room.mu.Unlock()
		
		if isEmpty {
			roomsMu.Lock()
			delete(rooms, room.Code)
			roomsMu.Unlock()
		} else {
			broadcastLobby(room)
		}
	}
	conn.Close()
}

func runGameLoop(r *Room) {
	ticker := time.NewTicker(time.Second / game.TickRate)
	defer ticker.Stop()
	for range ticker.C {
		// Game Ends check inside Update
		r.Game.Update()
		
		state := r.Game.GetState()
		data, _ := json.Marshal(map[string]interface{}{"type": "game_update", "state": state})
		
		r.mu.Lock()
		for _, p := range r.Players {
			p.Conn.WriteMessage(websocket.TextMessage, data)
		}
		r.mu.Unlock()
	}
}

func broadcastLobby(r *Room) {
	r.mu.Lock()
	defer r.mu.Unlock() // Simple lock for the duration

	list := make([]*game.PlayerInfo, 0)
	for _, p := range r.Players {
		list = append(list, p)
	}
	data, _ := json.Marshal(map[string]interface{}{"type": "lobby_update", "players": list, "status": r.Status})
	
	for _, p := range r.Players {
		p.Conn.WriteMessage(websocket.TextMessage, data)
	}
}
