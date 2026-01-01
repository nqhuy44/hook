package game

import (
	"fmt"
	"math"
	"math/rand"
	"sync"
	"time"
)

type Game struct {
	Entities      map[string]*Entity
	Projectiles   []*Projectile
	TeamScore     map[string]int
	KillFeed      []string
	TimeRemaining float64
	GameOver      bool
	Winner        string
	nextID        int
	mu            sync.RWMutex
}

func NewGame(players map[string]*PlayerInfo) *Game {
	g := &Game{
		Entities:      make(map[string]*Entity),
		Projectiles:   make([]*Projectile, 0),
		TeamScore:     map[string]int{"1": 0, "2": 0},
		KillFeed:      make([]string, 0),
		TimeRemaining: 300.0, // 5 Minutes
		nextID:        1000,
	}
	for _, p := range players {
		g.spawnPudge(p.Team, false, p)
	}
	rc := 0
	dc := 0
	for _, p := range players {
		if p.Team == TeamRadiant {
			rc++
		} else {
			dc++
		}
	}
	// Bot Logic: Only if <= 2 players
	if len(players) <= 2 {
		for i := rc; i < 5; i++ {
			g.spawnBot(TeamRadiant)
		}
		for i := dc; i < 5; i++ {
			g.spawnBot(TeamDire)
		}
	}
	return g
}

func (g *Game) getID() string {
	g.nextID++
	return fmt.Sprintf("%d", g.nextID)
}

func (g *Game) spawnPudge(team Team, isBot bool, pInfo *PlayerInfo) {
	startX := 100.0 // Move closer to base edge (was 200)
	if team == TeamDire {
		startX = MapWidth - 100.0 // Move closer to base edge (was 1400)
	}
	pos := Vector{X: startX, Y: 100 + rand.Float64()*(MapHeight-200)}
	id := g.getID()
	name := fmt.Sprintf("Bot %s", id)
	color := "#ffffff"

	if pInfo != nil {
		id = pInfo.ID
		name = pInfo.Name
		color = pInfo.Color
	} else {
		if team == TeamRadiant {
			color = "#00ff00"
		} else {
			color = "#ff0000"
		}
	}

	var avatarID string = "bot_basic"
	if pInfo != nil {
		avatarID = pInfo.AvatarID
	}

	g.Entities[id] = &Entity{
		ID:          id,
		Name:        name,
		Team:        team,
		Pos:         pos,
		TargetPos:   pos,
		Color:       color,
		AvatarID:    avatarID,
		MaxHP:       2000,
		MaxMana:     1000,
		Speed:       5.0,
		Radius:      20,
		IsBot:       isBot,
		AttackRange: 160,
		Damage:      70,
		Skills: []Skill{
			{Name: "Meat Hook", Key: "Q", MaxCD: 12, ManaCost: 120, Type: "point"},
			{Name: "Rot", Key: "W", MaxCD: 0.5, ManaCost: 0, Type: "toggle"},
			{Name: "Leap", Key: "E", MaxCD: 6, ManaCost: 50, Type: "point"},
			{Name: "Dismember", Key: "R", MaxCD: 20, ManaCost: 170, Type: "unit"},
		},
		HP:   2000,
		Mana: 1000,
	}
}

func (g *Game) spawnBot(team Team) { g.spawnPudge(team, true, nil) }

func (g *Game) Update() {
    g.mu.Lock()
    defer g.mu.Unlock()
    
    if g.GameOver { return }

    dt := 1.0 / float64(TickRate)
    g.TimeRemaining -= dt
    if g.TimeRemaining <= 0 {
        g.TimeRemaining = 0
        g.GameOver = true
        s1, s2 := g.TeamScore["1"], g.TeamScore["2"]
        if s1 > s2 { g.Winner = "RADIANT" } else if s2 > s1 { g.Winner = "DIRE" } else { g.Winner = "DRAW" }
        g.KillFeed = append(g.KillFeed, "GAME OVER: " + g.Winner + " WINS!")
    }
    
	if g.TeamScore["1"] >= WinScore || g.TeamScore["2"] >= WinScore {
		g.GameOver = true
		if g.TeamScore["1"] >= WinScore { g.Winner = "RADIANT" } else { g.Winner = "DIRE" }
        g.KillFeed = append(g.KillFeed, "VICTORY: " + g.Winner)
	}

	for _, e := range g.Entities {
		if e.Dead {
			e.RespawnCD -= dt
			if e.RespawnCD <= 0 {
				e.Dead = false
				e.HP = e.MaxHP
				e.Mana = e.MaxMana
				e.State = "idle"
                e.StunTimer = 0 // FIX: Clear stun on respawn
				e.Skills[1].Active = false
				bx := 100.0
				if e.Team == TeamDire {
					bx = MapWidth - 100.0
				}
				e.Pos = Vector{X: bx, Y: 100 + rand.Float64()*(MapHeight-200)} 
				e.TargetPos = e.Pos
			}
			continue
		}
		if e.HP < e.MaxHP { e.HP += 20.0 * dt } // Increased Regen
		if e.Mana < e.MaxMana { e.Mana += 15.0 * dt } // Increased Regen
		if e.StunTimer > 0 { 
            e.StunTimer -= dt
            e.State = "stunned" 
        } else if e.State == "stunned" {
            e.State = "idle"
            e.StunTimer = 0
            if e.IsBot {
                // Force Move on Wakeup
                minX := 50.0
                maxX := RiverX - RiverWidth/2
                if e.Team == TeamDire {
                    minX = RiverX + RiverWidth/2
                    maxX = MapWidth - 50
                }
                e.TargetPos = Vector{X: minX + rand.Float64()*(maxX-minX), Y: 100 + rand.Float64()*(MapHeight-200)}
                e.State = "move"
            }
        }
		if e.AttackCD > 0 { e.AttackCD -= dt }
		for i := range e.Skills {
			if e.Skills[i].Cooldown > 0 { e.Skills[i].Cooldown -= dt }
		}

		// Channeling
		if e.State == "channel" {
            e.ChannelTimer -= dt
			t, ok := g.Entities[e.ChannelID]
			// Break distance roughly twice cast range, or strict? "Radius same as rot" implies strict.
            // Rot radius 50. Let's start with 100 break distance to be slightly lenient.
			if !ok || t.Dead || distance(e.Pos, t.Pos) > 100 || e.StunTimer > 0 || e.ChannelTimer <= 0 {
				e.State = "idle"
				e.ChannelID = ""
			} else {
				t.StunTimer = 0.2
                // Dismember: 120 DPS, 100 Self Heal
				t.HP -= 120.0 * dt
                e.HP += 100.0 * dt
                if e.HP > e.MaxHP { e.HP = e.MaxHP }
                
				e.Rotation = math.Atan2(t.Pos.Y-e.Pos.Y, t.Pos.X-e.Pos.X)
				if t.HP <= 0 {
					g.kill(t, e)
				}
				continue
			}
		}

		// River Hazard (X: 720 to 880)
		if e.Pos.X > 720 && e.Pos.X < 880 {
			e.HP -= 50.0 * dt
			if e.HP <= 0 {
				g.kill(e, nil)
			}
		}

		// Rot
		if e.Skills[1].Active {
			e.HP -= 40.0 * dt
			for _, o := range g.Entities {
				if !o.Dead && o.Team != e.Team && distance(e.Pos, o.Pos) < 50 {
					o.HP -= 120.0 * dt
					if o.HP <= 0 {
						g.kill(o, e)
					}
				}
			}
			if e.HP <= 0 {
				g.kill(e, nil)
			}
		}

		if e.IsBot && e.State != "stunned" && e.State != "dragged" {
			g.updateBotAI(e)
		}
		if e.State == "dragged" || e.State == "stunned" {
			continue
		}

		// Attack
		if e.TargetID != "" {
			t, ok := g.Entities[e.TargetID]
			if !ok || t.Dead {
				e.TargetID = ""
				e.State = "idle"
			} else {
				if distance(e.Pos, t.Pos) <= e.AttackRange+e.Radius+t.Radius {
					e.TargetPos = e.Pos
					e.Rotation = math.Atan2(t.Pos.Y-e.Pos.Y, t.Pos.X-e.Pos.X)
					if e.AttackCD <= 0 {
						e.AttackCD = 0.9
						e.LastAttack = float64(time.Now().UnixNano()) / 1e9
                        if t.Team != e.Team { // FRIENDLY FIRE FIX
                            t.HP -= e.Damage
                            if t.HP <= 0 {
                                g.kill(t, e)
                            }
                        }
					}
				} else {
					e.TargetPos = t.Pos
					e.State = "move"
				}
			}
		}

		// Move & Boundary
		if e.State == "move" || e.IsBot {
			if distance(e.Pos, e.TargetPos) > 5.0 {
				dir := normalize(sub(e.TargetPos, e.Pos))
				newPos := add(e.Pos, mult(dir, e.Speed))

				// CORE MOVEMENT FIX:
				// Strict Walls at 720 and 880 (River Banks)
				// Unless Dragged (Hooked)
				canMove := true
				
				// Left Bank (720)
				if e.Pos.X <= 720 && newPos.X > 720 {
					newPos.X = 720
				} else if e.Pos.X > 720 && e.Pos.X < 880 {
					// Inside River - Trapped
					if newPos.X < 720 { newPos.X = 721 }
					if newPos.X > 880 { newPos.X = 879 }
				} else if e.Pos.X >= 880 && newPos.X < 880 {
					// Right Bank (880)
					newPos.X = 880
				}
				
				if canMove {
					e.Pos = newPos
					e.Rotation = math.Atan2(dir.Y, dir.X)
					// Boundary Clamp
					if e.Pos.X < 20 { e.Pos.X = 20 }
					if e.Pos.X > MapWidth-20 { e.Pos.X = MapWidth - 20 }
					if e.Pos.Y < 20 { e.Pos.Y = 20 }
					if e.Pos.Y > MapHeight-20 { e.Pos.Y = MapHeight - 20 }
				} else {
					e.TargetPos = e.Pos
				}
			}
		}
	}

	// Projectiles
	activeProjs := g.Projectiles[:0]
	for _, p := range g.Projectiles {
		keep := true
		if p.Returning {
			tp := p.StartPos
			if o, ok := g.Entities[p.FromID]; ok {
				tp = o.Pos
			}
			p.Pos = add(p.Pos, mult(normalize(sub(tp, p.Pos)), p.Speed))
			if p.HookedID != "" {
				if v, ok := g.Entities[p.HookedID]; ok {
					v.Pos = p.Pos
					v.State = "dragged"
				}
			}
			if distance(p.Pos, tp) < 30 {
				if v, ok := g.Entities[p.HookedID]; ok {
					v.State = "idle"
				}
				keep = false
			}
		} else {
			p.Pos = add(p.Pos, p.Vel)
			if distance(p.Pos, p.StartPos) > p.MaxDist {
				p.Returning = true
			}
			for _, e := range g.Entities {
				if e.ID != p.FromID && !e.Dead && distance(p.Pos, e.Pos) < (e.Radius+15) {
					p.Returning = true
					p.HookedID = e.ID
					if e.Team != p.Team {
						e.HP -= p.Damage
						if e.HP <= 0 {
							g.kill(e, g.Entities[p.FromID])
							p.HookedID = ""
						}
					}
					break
				}
			}
		}
		if keep {
			activeProjs = append(activeProjs, p)
		}
	}
	g.Projectiles = activeProjs
}

func (g *Game) updateBotAI(b *Entity) {
    // AGGRESSIVE MODE: If trapped on enemy side, always hunt nearest enemy
    if b.TerritoryBurn {
        nearest := g.getNearestEnemy(b, 2000) // Search wide
        if nearest != nil {
            // Kill logic
             b.TargetID = nearest.ID
             
             // Use Skills Aggressively
             dist := distance(b.Pos, nearest.Pos)
             
             // Ult if close
             ult := &b.Skills[3]
             if ult.Cooldown <= 0 && b.Mana >= ult.ManaCost && dist < 60 { 
                 b.State = "channel"
                 b.ChannelID = nearest.ID
                 b.ChannelTimer = 2.0 
                 ult.Cooldown = ult.MaxCD
                 b.Mana -= ult.ManaCost
                 return 
             }
             
             // Rot always on
             rot := &b.Skills[1]
             if !rot.Active { rot.Active = true }
             
             return // Don't wander if fighting
        }
    }


	if rand.Float64() < 0.005 || distance(b.Pos, b.TargetPos) < 10 { // Reduced wander chance
		minX := 50.0
		maxX := RiverX - RiverWidth/2
		if b.Team == TeamDire {
			minX = RiverX + RiverWidth/2
			maxX = MapWidth - 50
		}
		b.TargetPos = Vector{X: minX + rand.Float64()*(maxX-minX), Y: 100 + rand.Float64()*(MapHeight-200)}
		b.State = "move"
	}

	nearest := g.getNearestEnemy(b, 1000)
	if nearest != nil {
		dist := distance(b.Pos, nearest.Pos)

		// 1. DISMEMBER (Ult)
		ult := &b.Skills[3]
		if ult.Cooldown <= 0 && b.Mana >= ult.ManaCost && dist < 50 { 
			 b.State = "channel"
			 b.ChannelID = nearest.ID
			 b.ChannelTimer = 2.0 // 2s Duration
			 ult.Cooldown = ult.MaxCD
			 b.Mana -= ult.ManaCost
			 return 
		}

		// 2. ROT (unchanged)
		rot := &b.Skills[1]
		active := rot.Active
		if dist < 60 && !active { rot.Active = true }
		if dist >= 60 && active { rot.Active = false }

		// 3. HOOK (unchanged)
		hook := &b.Skills[0]
		if hook.Cooldown <= 0 && b.Mana >= hook.ManaCost && dist > 300 && dist < HookRange {
			t := dist / 17.0
			pred := add(nearest.Pos, mult(normalize(sub(nearest.TargetPos, nearest.Pos)), nearest.Speed*t))
			dir := normalize(sub(pred, b.Pos))
			g.Projectiles = append(g.Projectiles, &Projectile{ID: g.getID(), Type: "hook", Pos: b.Pos, StartPos: b.Pos, Vel: mult(dir, 17), Speed: 17, Damage: 300, Team: b.Team, MaxDist: HookRange, FromID: b.ID, Rotation: math.Atan2(dir.Y, dir.X)})
			hook.Cooldown = hook.MaxCD
			b.Mana -= hook.ManaCost
			b.Rotation = math.Atan2(dir.Y, dir.X)
		}
		
		// 4. LEAP (DISABLED to prevent teleport confusion)
		/*
		leap := &b.Skills[2]
		if leap.Cooldown <= 0 && b.Mana >= leap.ManaCost && dist > 400 && dist < 600 {
			 dir := normalize(sub(nearest.Pos, b.Pos))
			 b.Pos = add(b.Pos, mult(dir, 300))
			 b.TargetPos = b.Pos
			 leap.Cooldown = leap.MaxCD
			 b.Mana -= leap.ManaCost
		}
		*/
	} else {
        if b.Skills[1].Active { b.Skills[1].Active = false }
    }
}



func (g *Game) kill(v *Entity, k *Entity) {
	v.Dead = true
	v.RespawnCD = RespawnTime
	v.Skills[1].Active = false
	v.State = "dead"
	v.TargetID = ""
	v.TerritoryBurn = false
	kn := "Environment"
	if k != nil {
		k.Score++
		g.TeamScore[fmt.Sprintf("%d", k.Team)]++
		kn = k.Name
	} else {
		t := "1"
		if v.Team == TeamRadiant {
			t = "2"
		}
		g.TeamScore[t]++
	}
	g.KillFeed = append(g.KillFeed, fmt.Sprintf("%s killed %s (Score: %v)", kn, v.Name, g.TeamScore))
	if len(g.KillFeed) > 5 {
		g.KillFeed = g.KillFeed[1:]
	}
}

func (g *Game) getNearestEnemy(me *Entity, r float64) *Entity {
	var n *Entity
	minDist := r
	for _, e := range g.Entities {
		if e.Team != me.Team && !e.Dead {
			d := distance(me.Pos, e.Pos)
			if d < minDist {
				minDist = d
				n = e
			}
		}
	}
	return n
}

// HELPERS
func distance(a, b Vector) float64 { return math.Hypot(b.X-a.X, b.Y-a.Y) }
func sub(a, b Vector) Vector       { return Vector{a.X - b.X, a.Y - b.Y} }
func add(a, b Vector) Vector       { return Vector{a.X + b.X, a.Y + b.Y} }
func mult(v Vector, s float64) Vector { return Vector{v.X * s, v.Y * s} }
func normalize(v Vector) Vector {
	m := math.Hypot(v.X, v.Y)
	if m == 0 {
		return Vector{0, 0}
	}
	return Vector{v.X / m, v.Y / m}
}
func RandomColor() string {
	colors := []string{"#00ffff", "#ff00ff", "#ffff00", "#ff8800", "#0088ff"}
	return colors[rand.Intn(len(colors))]
}

func (g *Game) GetState() GameState {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return GameState{
		Entities:      g.Entities,
		Projectiles:   g.Projectiles,
		Score:         g.TeamScore,
		Feed:          g.KillFeed,
		TimeRemaining: g.TimeRemaining,
		GameOver:      g.GameOver,
		Winner:        g.Winner,
	}
}

func (g *Game) HandleInput(playerID, cmdType string, skillIdx int, x, y float64, targetID string) {
	g.mu.Lock()
	defer g.mu.Unlock()
	
	h, ok := g.Entities[playerID]
	if !ok || h.Dead {
		return
	}
	
	if cmdType == "move" {
		h.TargetPos = Vector{X: x, Y: y}
		h.State = "move"
		h.TargetID = ""
	}
	if cmdType == "stop" {
		h.TargetPos = h.Pos
		h.State = "idle"
		h.TargetID = ""
	}
	if cmdType == "attack" {
		h.TargetID = targetID
		h.State = "move"
	}
	if cmdType == "skill" {
		if skillIdx >= 0 && skillIdx < len(h.Skills) {
			s := &h.Skills[skillIdx]
			if s.Type == "toggle" {
				s.Active = !s.Active
			}
			if s.Cooldown <= 0 && h.Mana >= s.ManaCost {
				if s.Key == "R" && targetID != "" {
					t, ok := g.Entities[targetID]
					if ok && !t.Dead && distance(h.Pos, t.Pos) < 50 { // Reduced to near Rot range
						h.State = "channel"
						h.ChannelID = targetID
                        h.ChannelTimer = 2.0 // FIXED: 2s Duration
                        h.Mana -= s.ManaCost // Deduct Mana for Ult
                        s.Cooldown = s.MaxCD
					}
				} else if s.Key != "R" {
					h.Mana -= s.ManaCost
					s.Cooldown = s.MaxCD
					dir := normalize(sub(Vector{X: x, Y: y}, h.Pos))
					if s.Key == "Q" {
						g.Projectiles = append(g.Projectiles, &Projectile{ID: g.getID(), Type: "hook", Pos: h.Pos, StartPos: h.Pos, Vel: mult(dir, 17), Speed: 17, Damage: 300, Team: h.Team, MaxDist: HookRange, FromID: h.ID, Rotation: math.Atan2(dir.Y, dir.X)})
					} else if s.Key == "E" {
						h.Pos = add(h.Pos, mult(dir, 300))
						h.TargetPos = h.Pos
					}
				}
			}
		}
	}
}
