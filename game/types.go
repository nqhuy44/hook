package game

import (
    "github.com/gorilla/websocket"
)

const (
    TickRate    = 30
    MapWidth    = 1600.0
    MapHeight   = 900.0
    RiverX      = 800.0
    RiverWidth  = 160.0
    HookRange   = 850.0
    RespawnTime = 10.0
    WinScore    = 30
)

type Vector struct {
    X float64 `json:"x"`
    Y float64 `json:"y"`
}

type Team int

const (
    TeamRadiant Team = 1
    TeamDire    Team = 2
)

type PlayerInfo struct {
    ID       string          `json:"id"`
    Name     string          `json:"name"`
    Team     Team            `json:"team"`
    Color    string          `json:"color"`
    IsBot    bool            `json:"is_bot"`
    AvatarID string          `json:"avatar_id"`
    Conn     *websocket.Conn `json:"-"`
}

type Entity struct {
    ID            string  `json:"id"`
    Name          string  `json:"name"`
    Team          Team    `json:"team"`
    Pos           Vector  `json:"pos"`
    TargetPos     Vector  `json:"target_pos"`
    Rotation      float64 `json:"rotation"`
    HP            float64 `json:"hp"`
    MaxHP         float64 `json:"max_hp"`
    Mana          float64 `json:"mana"`
    MaxMana       float64 `json:"max_mana"`
    Speed         float64 `json:"speed"`
    Radius        float64 `json:"radius"`
    Dead          bool    `json:"dead"`
    RespawnCD     float64 `json:"respawn_cd"`
    IsBot         bool    `json:"is_bot"`
    Color         string  `json:"color"`
    TargetID      string  `json:"target_id"`
    AvatarID      string  `json:"avatar_id"`
    State         string  `json:"state"`
    Skills        []Skill `json:"skills"`
    StunTimer     float64 `json:"stun_timer"`
    ChannelTimer  float64 `json:"channel_timer"`
    ChannelID     string  `json:"channel_id"`
    Score         int     `json:"score"`
    AttackRange   float64
    Damage        float64
    AttackCD      float64
    LastAttack    float64
    TerritoryBurn bool `json:"territory_burn"`
}

type Skill struct {
    Name     string  `json:"name"`
    Key      string  `json:"key"`
    Cooldown float64 `json:"cooldown"`
    MaxCD    float64 `json:"max_cd"`
    ManaCost float64 `json:"mana_cost"`
    Type     string  `json:"type"`
    Active   bool    `json:"active"`
}

type Projectile struct {
    ID        string  `json:"id"`
    Type      string  `json:"type"`
    Pos       Vector  `json:"pos"`
    StartPos  Vector  `json:"start_pos"`
    Vel       Vector  `json:"vel"`
    Speed     float64 `json:"speed"`
    Damage    float64 `json:"damage"`
    Team      Team    `json:"team"`
    FromID    string  `json:"from_id"`
    MaxDist   float64 `json:"max_dist"`
    Returning bool    `json:"returning"`
    HookedID  string  `json:"hooked_id"`
    Rotation  float64 `json:"rotation"`
}

type GameState struct {
    Entities      map[string]*Entity `json:"entities"`
    Projectiles   []*Projectile      `json:"projectiles"`
    Score         map[string]int     `json:"score"`
    Feed          []string           `json:"feed"`
    TimeRemaining float64            `json:"time_remaining"`
    GameOver      bool               `json:"game_over"`
    Winner        string             `json:"winner"`
}
