# HooK - Technical Design & Game Plan

This document outlines the architecture, mechanics, and configuration of the **HooK** game engine.

## 1. System Architecture

The game uses a **Server-Authoritative** architecture to prevent cheating and ensure synchronization.

### Backend (Go)
-   **Game Loop**: Runs at **30 Ticks Per Second (TPS)**.
-   **State Management**: The server holds the "True State" of all entities (Position, HP, Mana, Cooldowns).
-   **Concurrency**:
    -   **Main Loop**: A `time.Ticker` triggers the `Update()` function every 33ms.
    -   **Mutex Protection**: A `sync.RWMutex` (`g.mu`) protects the shared Game State, allowing concurrent WebSocket reads (player input) and writes (broadcasting).
-   **Communication**: Sends JSON state snapshots to all connected clients every tick.

### Frontend (JavaScript/Canvas)
-   **Rendering**: `requestAnimationFrame` loop draws the state received from the server.
-   **Interpolation**: (Currently direct state rendering) - The client renders the exact X/Y received. *Future improvement: Linear interpolation for smoother 60FPS visuals on 30Hz server.*
-   **Input**: Listens for Mouse (Move/Click) and Keyboard (Q/W/E/R) events and sends them immediately to the server.

---

## 2. Game Mechanics

### Core Object: The Hook (Q)
-   **Type**: Projectile.
-   **Physics**: Moves linearly. Bounces off map borders (`Vel.Y *= -1`).
-   **Collision**: Uses simple Circle-Circle intersection (`distance < radius1 + radius2`).
-   **Interaction**: If it hits a unit:
    -   **Damage**: Deals pure damage.
    -   **Status**: Flags victim as "Hooked".
    -   **Drag**: Victim's position is locked to the Hook tip as the hook retracts to the caster.

### Skills System
Defined in `game/engine.go` -> `Skill` struct.
1.  **Meat Hook (Q)**: See above. Long range, pure damage.
2.  **Rot (W)**: Toggle.
    -   **Effect**: Deals damage over time (DoT) to enemies in **50 radius** (Damage Radius) / **60 radius** (Bot Activation).
    -   **Cost**: No Mana, but slows the caster? (Currently implementation is basic DoT).
3.  **Leap (E)**: Point Target (Currently simpler movement).
4.  **Dismember (R)**: Channeling.
    -   **Effect**: Stuns target for 2 seconds.
    -   **Range**: Melee (50).
    -   **Interrupt**: Moving cancels channel.

### Map & Territory
-   **Dimensions**: 1600x900.
-   **The River**: Central line dividing Radiant (Left) and Dire (Right).
-   **Territory Burn**: If a hero crosses the river (X > 800 for Radiant), they take massive DPS ("Wrong Side" mechanic).
    -   *Strategy*: Pull enemies across the river with Hook to kill them with Territory Burn.

---

## 3. Configuration & Constants

Found in `game/types.go` and `engine.go`.

| Constant | Value | Description |
| :--- | :--- | :--- |
| `TickRate` | 30 | Server updates per second. |
| `MapWidth` | 1600 | Width of game field. |
| `MapHeight` | 900 | Height of game field. |
| `RiverX` | 800 | The dividing line. |
| `HookRange` | 850 | Max distance hook travels (can cross river). |
| `RespawnTime`| 10s | Time before hero reappears at base. |
| `WinScore` | 30 | Kills required to end match. |

---

## 4. Logs & Metrics

-   **Console Logs**: The server logs connection events ("Client connected") and startup info.
-   **Kill Feed**: In-game event log (`GameState.Feed`).
    -   Generated in `kill()` method (`engine.go`).
    -   Format: `["KillerName killed VictimName", ...]`.
    -   Broadcasted as part of `GameState` JSON.

## 5. Future Roadmap

1.  **Interpolation**: Client-side smoothing.
2.  **Database**: Save stats/high scores (currently in-memory only).
3.  **Chat System**: In-game text chat.
4.  **Items**: Shop system to buy Speed/Mana/Cooldown items.
